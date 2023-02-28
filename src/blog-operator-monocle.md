This post aims to explains how we built a k8s Operator using the [operator sdk][operator sdk] for
the [Monocle][Monocle] project. We'll cover the following topics:

- What is a k8s Operator
- How to create the project skeleton
- Workflows related to the Monocle's operations
- Handling Monocle' workflows with the Operator
- How to test the Operator
- How to deploy the operator in production


## What is a k8s Operator ?

An [Operator][operator pattern] is a software capables of handling various operations related to
another software. The Operator handles operations usually ensured by a SRE.

Handled operations are such as (but not limited to):

- Deployment
- Re-configuration
- Update
- Scaling
- Backup

Capabilities of an operator are splitted in [phases][operator-phases] as described in the
Operator framework documentation.

To create an Operator a developer needs to well understand how to operate
the target software.

A multitude of Operators for various softwares are already available especially
on [Operator Hub][Operator Hub].

An Operator is designed to live inside a k8s or OpenShift deployment. The operator
uses k8s' resources (Deployment, ConfigMap, ...) to handle the target software'
operations. It defines at least one CR ([Custom Resource][custom resource]) that can be configured via
a CRD ([Custom Resource Definition][custom resource definition]) and a Custom Controller by CR.

A Custom Controller watches for instances of a CR and ensures that k8s' resources
needed by the CR's instance are spawned and fully functional. The controller
runs continuously and reacts to various events ensuring the declared state
of the software is maintained. This is called "Reconciliation".

In this blog post we introduce an Operator for the Monocle software, based on a
Custom Resource and a Custom controller. The controller is implemented in Go to
benefit from well tested and documented libraries.

## How to create the project skeleton ?

The [Operator framework project][Operator framework project] provides a [SDK][operator sdk]
to ease the bootstrap and maintainance of an operator.

First install the [GO operator SDK][go operator SDK]:

```bash
curl -OL https://github.com/operator-framework/operator-sdk/releases/download/v1.26.0/operator-sdk_linux_amd64
mkdir -p ~/.local/bin && mv operator-sdk_linux_amd64 ~/.local/bin/operator-sdk && chmod +x ~/.local/bin/operator-sdk
```

[Initialise your repository][sdk-init] using the `init` sub command:

```bash
mkdir monocle-operator && cd monocle-operator
git init .
operator-sdk init --repo github.com/change-metrics/monocle-operator --owner "Monocle developers" --domain monocle.change-metrics.io
git diff
git add -A . && git commit -m"Init the operator"
```

Then, [add the new API][sdk-create-api] (a CRD) and a controller for the new Custom Resource `Monocle`:

```bash
operator-sdk create api --group monocle --version v1alpha1 --kind Monocle --resource --controller
git status
git diff
git add -A . && git commit -m"Add skeleton code for the Monocle CR"
```

If the Operator handles more CRs then run the previous command with the new `Kind`.

The SDK for a [GO operator][go operator SDK] generates the project code structure composed of
various files and directories. Check the [layout details here][operator-sdk-layout].

We can see that an Operator is, at least defined, by the following resources:

- A [manager][controller-runtime manager] and a set of [controllers][controller-runtime controller]
- A set of [CRDs][custom resource definition]
- A container image capable of running the `manager`
- A suite of YAML manifests to apply to the Kubernetes cluster to deploy the operator

From there we are ready to write the Monocle Operator.

## Workflows related to the Monocle's operations

An operator handles various workflows for the targeted software. Thus, as a first step we need
to identify exactly what are those workflows and what they involve.

For our `Day 1` journey we'd like to handle the deployment and the configuration of Monocle.
It is important to have a minimum understanding of the software we intent to create an operator
for so feel free to read the [Monocle's README file][monocle-readme].

### Deployment

A minimal Monocle deployment is composed of three services. The upstream
project provide a [Docker Compose recipe][monocle-compose] that we will replicate.

#### The database (ElasticSearch)

Monocle needs to get access to an ElasticSearch instance:

- The service needs a storage for its indices.
- We can use the upstream ElasticSearch container image.
- We can rely on the minimal and default settings.

#### The Monocle API (serve the API and the WEB UI)

- The upstream project provides a container image.
- The service a stateless.
- A configuration file is needed.
- Some environment variables must be exposed (especially for the secrets).

#### The Monocle crawler

The crawler requires the same as the API.

### Configuration

Here we need to determine how an User will interact with the Monocle Operator
in order to change the Monocle configuration.

#### Update secrets

The [secrets][monocle-secrets] hosts sensitive information used by the API and the crawler
processes (Code Review provider's API tokens, OpenID Token, ...). Any changes to
the `secrets` require an API and crawler processes restart.

#### Update config.yaml

The [config file][monocle-config] is used by the API and the crawler. Monocle
is able to detect changes in its configuration file and reload the configuration.

The `janitor update-idents` command must be run in case of updating the `config file`
to [update identities][monocle-identities].

## Handling Monocle' workflows with the Operator

As we know better about workflow we need to implement inside our Monocle
controller we can start implementing. We'll just explain some code blocks.

### The reconcile loop

The operator SDK generated an empty Monocle's `Reconcile` function.

This function aims to make the requested state (by applying the `Monocle` resource) state
in the cluster. When a `Monocle` resource exists we want to provide a working Monocle deployment
with the database, the api, and the crawler.

Furthermore various attributes can configured in the `spec` (see `api/v1alpha1/monocle_types.go`)
so we need to get the instance's `spec` to gather all information about the expected state.

To do so we fill the function in order to get the Monocle instance Resource according
to the [req][controller-runtime-req] content:

```Go
func (r *MonocleReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {

   var (
		logger         = log.FromContext(ctx)
		reconcileLater = func(err error) (
			ctrl.Result, error) {
			return ctrl.Result{RequeueAfter: time.Second * 5}, err
		}
		stopReconcile = func() (
			ctrl.Result, error) {
			return ctrl.Result{}, nil
		}
		instance = monoclev1alpha1.Monocle{}
	)

   // Get the Monocle instance related to request
	err := r.Client.Get(ctx, req.NamespacedName, &instance)
	if err != nil {
		if k8s_errors.IsNotFound(err) {
			// Request object not found. Return and don't requeue.
			logger.Info("Instance object not found. Stop reconcile.")
			// Stop reconcile
			return stopReconcile()
		}
		// Error reading the object - requeue the request.
		logger.Info("Unable to read the Monocle object. Reconcile continues ...")
		// Stop reconcile
		return reconcileLater(err)
	}

   logger.Info("Found Monocle object.")
	return stopReconcile()
}
```

This `Reconcile` function is called each time an event occurs on a Monocle instance such as by
an apply or an update:

```bash
$ kubectl apply -f config/samples/monocle_v1alpha1_monocle.yaml
$ kubectl edit Monocle monocle-sample
```

The `operator-sdk create api` created a default `config/samples/monocle_v1alpha1_monocle.yaml` file that we
can use to reclaim an instance the `Monocle` Custom Resource.

Start the manager in dev mode:

```bash
$ make run
# or go run ./main.yaml
```

In another terminal you can `apply` the resource with:

```bash
$ kubectl apply -f config/samples/monocle_v1alpha1_monocle.yaml
```

Then the `Monocle's controller` should display and stop the reconcile loop:

```bash
1.6781911388888087e+09  INFO    controller-runtime.metrics      Metrics server is starting to listen    {"addr": ":8080"}
...
1.6781911390910478e+09  INFO    Starting workers        {"controller": "monocle", "controllerGroup": "monocle.monocle.change-metrics.io", "controllerKind": "Monocle", "worker count": 1}
1.6781911505580697e+09  INFO    Found Monocle object.   {"controller": "monocle", "controllerGroup": "monocle.monocle.change-metrics.io", "controllerKind": "Monocle", "Monocle": {"name":"monocle-sample","namespace":"fbo"}, "namespace": "fbo", "name": "monocle-sample", "reconcileID": "580d1b93-e4d8-41ef-8996-817e198727ff"}
```

You can observe that the `controller` re-enters the reconcile loop when we edit the Monocle instance:

```bash
# Add a new label in metadata.labels and save.
$ kubectl edit monocle monocle-sample
```

The return value of the reconcile function controls how the `controller` re-enter it. See
[details here][controller-runtime-reconcile].

Next steps are to handle the deployment of the services that compose a Monocle deployment.

### How the operator starts Monocle' components

We'll only focus on the `api` service in that section. Other services are pretty similar
expected the database service that is deployed via the [StatefulSet][k8s-statefullset].

Feel free to refer to the [complete controller code][monocle-controller].

#### The API secret

The `Monocle` API service needs to access some secrets data. Here we use the [secret][k8s-secret]
resource to store this data.

The Monocle's controller needs to:

- Check if the secret exist
- Create the secret resource if it does not exist
- Continue if it exists

The `secret` is identified by its name and must be unique in the `namespace`.

Here is how we handle the `secret` resource ([type][k8s-core-secrets]):

```Go
////////////////////////////////////////////////////////
//       Handle the Monocle API Secret Instance       //
////////////////////////////////////////////////////////

// This secret contains environment variables required by the
// API and/or crawlers. The CRAWLERS_API_KEY entry is
// mandatory for crawlers to authenticate against the API.

// preprend the resource name with the instance name
apiSecretName := resourceName("api")
// initialize a mapping with a random crawler's api key
apiSecretData := map[string][]byte{
	"CRAWLERS_API_KEY": []byte(randstr.String(24))}
// create the secret instance with required metadata for the lookup
apiSecret := corev1.Secret{
	ObjectMeta: metav1.ObjectMeta{
		Name:      apiSecretName,
		Namespace: req.Namespace},
}
// get the secret resource by name
err = r.Client.Get(
	ctx, client.ObjectKey{Name: apiSecretName, Namespace: req.Namespace}, &apiSecret)
if err != nil && k8s_errors.IsNotFound(err) {
   // The resource does not exist yet. Let's create it.
   // Set secret data
	apiSecret.Data = apiSecretData
   // Add an owner reference (Monocle instance) on the secret resource
	if err := ctrl_util.SetControllerReference(&instance, &apiSecret, r.Scheme); err != nil {
		logger.Info("Unable to set controller reference", "name", apiSecretName)
		return reconcileLater(err)
	}
	// Create the secret
	logger.Info("Creating secret", "name", apiSecretName)
	if err := r.Create(ctx, &apiSecret); err != nil {
		logger.Info("Unable to create secret", "name", apiSecretName)
		return reconcileLater(err)
	}
} else if err != nil {
	// Handle the unexpected err
	logger.Info("Unable to get resource", "name", apiSecretName)
	return reconcileLater(err)
} else {
	// Eventually handle resource update
	logger.Info("Resource fetched successfuly", "name", apiSecretName)
}

// Get the resource version - to be used later ...
apiSecretsVersion := apiSecret.ResourceVersion
logger.Info("apiSecret resource", "version", apiSecretsVersion)
```

As you can see, the code detects the secret state and perform actions
according to the state. We use the [Client][controller-runtime-client] exposed through the `MonocleReconcilier`
interface to perform CRUD actions. This is a common pattern that we'll use for other resources managed
by the controller.

#### The API config

The [ConfigMap][k8s-config-map]([type][k8s-core-configmap]) are pretty similar regarding their API so
the code below is the same as for the `secret`.

```Go
////////////////////////////////////////////////////////
//     Handle the Monocle API ConfigMap Instance      //
////////////////////////////////////////////////////////

// preprend the resource name with the instance name
apiConfigMapName := resourceName("api")
// initialize a mapping with the default config file
apiConfigMapData := map[string]string{
	"config.yaml": `
workspaces:
  - name: demo
    crawlers: []
`}
// create the config-map instance with required metadata for the lookup
apiConfigMap := corev1.ConfigMap{
	ObjectMeta: metav1.ObjectMeta{
		Name:      apiConfigMapName,
		Namespace: req.Namespace},
}

// get the configmap resource by name
err = r.Client.Get(
	ctx, client.ObjectKey{Name: apiConfigMapName, Namespace: req.Namespace}, &apiConfigMap)
if err != nil && k8s_errors.IsNotFound(err) {
   // The resource does not exist yet. Let's create it.
	apiConfigMap.Data = apiConfigMapData
   // Add an owner reference (Monocle instance) on the configmap resource
	if err := ctrl_util.SetControllerReference(&instance, &apiConfigMap, r.Scheme); err != nil {
		logger.Info("Unable to set controller reference", "name", apiConfigMapName)
		return reconcileLater(err)
	}
	// Create the configMap
	logger.Info("Creating ConfigMap", "name", apiConfigMapName)
	if err := r.Create(ctx, &apiConfigMap); err != nil {
		logger.Info("Unable to create configMap", "name", apiConfigMap)
		return reconcileLater(err)
	}
} else if err != nil {
	// Handle the unexpected err
	logger.Info("Unable to get resource", "name", apiConfigMapName)
	return reconcileLater(err)
} else {
	// Eventually handle resource update
	logger.Info("Resource fetched successfuly", "name", apiConfigMapName)
}

// Get the resource version - to be used later ...
apiConfigVersion := apiConfigMap.ResourceVersion
logger.Info("apiConfig resource", "version", apiConfigVersion)
```

For all resources created by the Monocle `controller` we set a [OwnerReference][k8s-owner-references].
This ensures that when we delete the CR instance then all dependents resources are also
deleted. It serves also to the `manager` to call the reconcile function when a dependent resource
is updated.

#### The API deployment

To run the API service we use the [Deployment resource][k8s-deployment]([type][k8s-core-deployment]) and
in front of it we configure a [Service][k8s-service]([type][k8s-core-service]) resource.

A `Deployment` manages a set of `Pods` according to rules and workflows implemented in the `Deployment`'s
controller.

As `Pods` can be spawned on different cluster' nodes then container' IP addresses can change then
a `Service` resource is needed on top of a `Deployment`.

Let's start by creating `api-service` resource:

```Go
// Handle service for api //
////////////////////////////

// The monocle API listen to 8080/TCP
apiPort := 8080
// MatchLabels shared between the service and the deployment
apiMatchLabels := map[string]string{
	"app":  "monocle",
	"tier": "api",
}
// Service resource name
apiServiceName := resourceName("api")
// Instanciate a Service object for the lookup
apiService := corev1.Service{
	ObjectMeta: metav1.ObjectMeta{
		Name:      apiServiceName,
		Namespace: req.Namespace,
	},
}

// Get the service by name
err = r.Client.Get(
	ctx, client.ObjectKey{Name: apiServiceName, Namespace: req.Namespace}, &apiService)
if err != nil && k8s_errors.IsNotFound(err) {
   // Resource is not found
   // Define the Service resource to create
	apiService.Spec = corev1.ServiceSpec{
		Ports: []corev1.ServicePort{
			{
				Name:     resourceName("api-port"),
				Protocol: corev1.ProtocolTCP,
				Port:     int32(apiPort),
			},
		},
      // The labels used to discover deployment' Pods
		Selector: apiMatchLabels,
	}
   // Add an owner reference (Monocle instance) on the service resource
	if err := ctrl_util.SetControllerReference(&instance, &apiService, r.Scheme); err != nil {
		logger.Info("Unable to set controller reference", "name", apiServiceName)
		return reconcileLater(err)
	}
	logger.Info("Creating Service", "name", apiServiceName)
   // Create the resource
	if err := r.Create(ctx, &apiService); err != nil {
		logger.Info("Unable to create service", "name", apiService)
		return reconcileLater(err)
	}
} else if err != nil {
	// Handle the unexpected err
	logger.Info("Unable to get resource", "name", apiServiceName)
	return reconcileLater(err)
} else {
	// Eventually handle resource update
	logger.Info("Resource fetched successfuly", "name", apiServiceName)
}
```

Now let's see how the Monocle API is deployed. It leverages the `Deployment` resource to
start a `Pod` containing one `Monocle` container based on the upstream container image.

```Go
// Handle API deployment //
///////////////////////////

// Service resource name
apiDeploymentName := resourceName("api")
apiDeployment := appsv1.Deployment{
	ObjectMeta: metav1.ObjectMeta{
		Name:      apiDeploymentName,
		Namespace: req.Namespace,
	},
}
apiReplicasCount := int32(1)

// We read the Monocle Public URL value passed via the CRD
monoclePublicURL := "http://localhost:8090"
if instance.Spec.MonoclePublicURL != "" {
	monoclePublicURL = instance.Spec.MonoclePublicURL
}
logger.Info("Monocle public URL set to", "url", monoclePublicURL)

// Get the deployment by name
err = r.Client.Get(
	ctx, client.ObjectKey{Name: apiDeploymentName, Namespace: req.Namespace}, &apiDeployment)
if err != nil && k8s_errors.IsNotFound(err) {
	// Setup the deployment object
	apiConfigMapVolumeName := resourceName("api-cm-volume")
	// Once created Deployment selector is immutable
	apiDeployment.Spec.Selector = &metav1.LabelSelector{
      // Enable relation between Pod, Deployment and Service
		MatchLabels: apiMatchLabels,
	}
	// Set replicas count
	apiDeployment.Spec.Replicas = &apiReplicasCount
	// Set the Deployment annotations
	apiDeployment.Annotations = map[string]string{
      // Here we set the Resource version of the Monocle ConfigMap
		"apiConfigVersion": apiConfigVersion,
	}

	// Set the Deployment pod template
	apiDeployment.Spec.Template = corev1.PodTemplateSpec{
		ObjectMeta: metav1.ObjectMeta{
         // Enable relation between Pod, Deployment and Service
			Labels: apiMatchLabels,
         // Here we set the Resource version of the Monocle secrets
         // Any update on the Template (here the annotation) starts a rollout
			Annotations: map[string]string{
				"apiSecretsVersion": apiSecretsVersion,
			},
		},
		Spec: corev1.PodSpec{
			RestartPolicy: corev1.RestartPolicyAlways,
			Containers: []corev1.Container{
				{
					Name:    resourceName("api-pod"),
					Image:   "quay.io/change-metrics/monocle:1.8.0",
					Command: []string{"monocle", "api"},
               // This exposes the Secret as environment variables into the running container
					EnvFrom: []corev1.EnvFromSource{
						{
							SecretRef: &corev1.SecretEnvSource{
								LocalObjectReference: corev1.LocalObjectReference{
									Name: apiSecretName,
								},
							},
						},
					},
               // An additional environment variable
					Env: []corev1.EnvVar{
						elasticUrlEnvVar,
						{
							Name:  "MONOCLE_PUBLIC_URL",
							Value: monoclePublicURL,
						},
					},
               // We defines ports exposed by the container
					Ports: []corev1.ContainerPort{
						{
							ContainerPort: int32(apiPort),
						},
					},
               // Define the live test probe
               // The Monocle API exposes the '/health' endpoint
					LivenessProbe: &corev1.Probe{
						ProbeHandler: corev1.ProbeHandler{
							HTTPGet: &corev1.HTTPGetAction{
								Path: "/health",
								Port: intstr.FromInt(apiPort),
							},
						},
						TimeoutSeconds:   30,
						FailureThreshold: 6,
					},
               // A Volume device is exposed to the container
               // We mount it into /etc/monocle. It contains the Monocle config file.
					VolumeMounts: []corev1.VolumeMount{
						{
							Name:      apiConfigMapVolumeName,
							ReadOnly:  true,
							MountPath: "/etc/monocle",
						},
					},
				},
			},
         // Expose a Volume device to the Pod' containers
         // The Volume is API ConfigMap that we expose as a volume.
			Volumes: []corev1.Volume{
				{
					Name: apiConfigMapVolumeName,
					VolumeSource: corev1.VolumeSource{
						ConfigMap: &corev1.ConfigMapVolumeSource{
							LocalObjectReference: corev1.LocalObjectReference{
								Name: apiConfigMapName,
							},
						},
					},
				},
			},
		},
	}
   // Add an owner reference (Monocle instance) on the deployment resource
	if err := ctrl_util.SetControllerReference(&instance, &apiDeployment, r.Scheme); err != nil {
		logger.Info("Unable to set controller reference", "name", apiDeploymentName)
		return reconcileLater(err)
	}
	logger.Info("Creating Deployment", "name", apiDeploymentName)
	// Create the resource
	if err := r.Create(ctx, &apiDeployment); err != nil {
		logger.Info("Unable to create deployment", "name", apiDeploymentName)
		return reconcileLater(err)
	}
} else if err != nil {
	// Handle the unexpected err
	logger.Info("Unable to get resource", "name", apiDeploymentName)
	return reconcileLater(err)
} else {
	// Eventually handle resource update
	logger.Info("Resource fetched successfuly", "name", apiDeploymentName)
}
```

Some key points that are important here:

- The `Deployment` ensures that we always have a working `Pod` that serves the Monocle API.
- The [liveness probe][k8s-liveness-probes] is used by the `Deployment` to ensure the Monocle API
  is ready. The `Deployment`'s status is based on the probe's status.
- We expose the configuration file from a [ConfigMap][k8s-config-map] using a [volume][k8s-config-map-volume].
  When the `configMap`'s data is updated exposed files are updated on the volume mount.
- We expose the `Secret` resource containing Monocle' secrets [as environment variables][k8s-secrets-as-env-vars].


Assuming that others Monocle' services are setup in the controller we can inspect `Resources`
spawned by the `controller` when we reclaim a `Monocle` resource.

```bash
$ cat config/samples/monocle_v1alpha1_monocle-alt.yaml
apiVersion: monocle.monocle.change-metrics.io/v1alpha1
kind: Monocle
metadata:
  labels:    app.kubernetes.io/name: monocle
    app.kubernetes.io/instance: monocle-sample
    app.kubernetes.io/part-of: monocle-operator
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/created-by: monocle-operator
  name: monocle-samplespec:
  monoclePublicURL: "http://localhost:8090"
$ kubectl apply -f config/samples/monocle_v1alpha1_monocle-alt.yaml
$ kubectl get statefulset,deployment,replicaset,service,configmap,secret
NAME                                      READY   AGE
statefulset.apps/monocle-sample-elastic   1/1     15s

NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/monocle-sample-api       1/1     1            1           15s
deployment.apps/monocle-sample-crawler   1/1     1            1           15s

NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/monocle-sample-api-8cd74454f        1         1         1       15s
replicaset.apps/monocle-sample-crawler-7fc7f659b7   1         1         1       15s

NAME                             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/monocle-sample-api       ClusterIP   10.96.36.244   <none>        8080/TCP   15s
service/monocle-sample-elastic   ClusterIP   10.96.68.155   <none>        9200/TCP   15s

NAME                           DATA   AGE
configmap/kube-root-ca.crt     1      21h
configmap/monocle-sample-api   1      15s

NAME                        TYPE     DATA   AGE
secret/monocle-sample-api   Opaque   1      15s
```

Enabling the Monocle WEB UI access served by the API can be done using the `port-forward`:

```bash
$ kubectl port-forward service/monocle-sample-api 8090:8080
$ firefox http://localhost:8090
```

### How the operator handles Monocle' reconfigurations

Now let's see how we handled the (re-)configuration workflow.

As [described previously](#Configuration) we need to handle:

- A change to the Monocle `Secret` resource restarts the API and the Crawler `Pods`.
- A change to the Monocle config file (store in the `ConfigMap` resource) triggers
  the `update-idents` CLI command.

#### Handling Secret changes

API and Crawler processes are handled by the [Deployment Resource][k8s-deployment]. This resource's
controller handles a [rollout][k8s-deployment-rollout] workflow when the `podSpec`'s `Image` field
or the `podTemplateSpec`'s annotations are updated.
A `rollout` restarts `Pods` in safe manner according to the configured rollout strategy.

To ensure that API and Crawlers containers are restarted when the Monocle's administrator
changes the secrets we used an annotation (we only focus on the API,
same apply for the Crawler's Deployment):

```Go
// else case (an API Deployment resource exists) of the API deployment part
} else {
	// Eventually handle resource update
	logger.Info("Resource fetched successfuly", "name", apiDeploymentName)

   // We call the rollOutWhenApiSecretsChange function
	err := r.rollOutWhenApiSecretsChange(ctx, logger, apiDeployment, apiSecretsVersion)
	if err != nil {
		logger.Info("Unable to update spec deployment annotations", "name", apiDeploymentName)
		reconcileLater(err)
	}
}
```

```Go
func (r *MonocleReconciler) rollOutWhenApiSecretsChange(ctx context.Context, logger logr.Logger, depl appsv1.Deployment, apiSecretsVersion string) error {
	previousSecretsVersion := depl.Spec.Template.Annotations["apiSecretsVersion"]
	if previousSecretsVersion != apiSecretsVersion {
		logger.Info("Start a rollout due to secrets update",
			"name", depl.Name,
			"previous secrets version", previousSecretsVersion,
			"new secrets version", apiSecretsVersion)
		depl.Spec.Template.Annotations["apiSecretsVersion"] = apiSecretsVersion
		return r.Update(ctx, &depl)
	}
	return nil
}
```

At `Deployment` creation we set the `apiSecretsVersion` annotation, and each time the `Reconcile` is called
the `rollOutWhenApiSecretsChange` function check if the resources version changed. In the case of a change
(meanning that the administrator changed one of the Monocle secrets) we do an `Update` of the annotation
to store the new `apiSecretsVersion` value.

This has the effect triggering the Deployments rollout and get `Pods' to be restarted.

This can be observed by editing the secrets to add a new one, then ensuring pod is re-spawned and that
the new secret is available in the `env` of the pod's container:

```bash
# A secret value must be encoded as base64
$ kubectl edit secrets monocle-sample-api
$ kubectl get pods
$ kubectl exec -it monocle-sample-api-c75dcc789-gmwwm -- env | grep -i <new-secret>
```

However, it's worth mentionning that the `Reconcile` function of the `Monocle` CR is not called
automatically by the controller when the Secret resource is changed. To get that behavior we need
to setup the [Manager][controller-runtime manager] to react to dependent resource' changes.

```Go
// SetupWithManager sets up the controller with the Manager.
func (r *MonocleReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&monoclev1alpha1.Monocle{}).
		Owns(&appsv1.Deployment{}).
		Owns(&corev1.ConfigMap{}).
		Owns(&corev1.Secret{}).
		Owns(&appsv1.StatefulSet{}).
		Owns(&corev1.Service{}).
		Complete(r)
}
```

The [Owns][controller-runtime-owns] coupled to the [owner references][k8s-owner-reference] ensure
that the `Reconcile` fonction is called when a dependent resource is updated.

#### Handling Config changes

The `ConfigMap` that stores the Monocle's config `config.yaml` is exposed as a `Volume Mount`
in `/etc/monocle` and Monocle knows how to reload itself when config when the file change.

However we need to detect updates on the `ConfigMap` and start a Monocle's CLI command
to [update idents][monocle-identities]. To do that we use a [Job][k8s-jobs] Resource ([type][k8s-core-jobs]).

The `Job` starts a `Pod` and reports execution status of the container's command.

Similarly to the Monocle secrets we store, in an annotation on the API `Deployment` resource, the
`ResourceVersion` of the `ConfigMap` and by checking for version change we can create a `Job`
resource and trigger the CLI command.

```Go
// else case (an API Deployment resource exists) of the API deployment part
} else {
	// Eventually handle resource update
	logger.Info("Resource fetched successfuly", "name", apiDeploymentName)

   ...
	// Check if Deployment Pod Annotation for ConfigMap resource version was updated
	previousVersion := apiDeployment.Annotations["apiConfigVersion"]
	if previousVersion != apiConfigVersion {

		logger.Info("Start the update-idents jobs because of api configMap update",
			"name", apiDeployment.Name,
			"previous configmap version", previousVersion,
			"new configmap version", apiConfigVersion)
		apiDeployment.Annotations["apiConfigVersion"] = apiConfigVersion
		// Update Deployment Resource to set the new configMap resource version
		err := r.Update(ctx, &apiDeployment)
		if err != nil {
			return reconcileLater(err)
		}
		// Trigger the job
		err = triggerUpdateIdentsJob(r, ctx, instance, req.Namespace, logger, elasticUrlEnvVar, apiConfigMapName)
		if err != nil {
			logger.Info("Unable to trigger update-idents", "name", err)
			reconcileLater(err)
		}
	}
}
```

```Go
func triggerUpdateIdentsJob(
      r *MonocleReconciler, ctx context.Context, instance monoclev1alpha1.Monocle,
      namespace string, logger logr.Logger, elasticUrlEnvVar corev1.EnvVar, apiConfigMapName string) error {

	jobname := "update-idents-job"
	job := batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			Name:      jobname,
			Namespace: namespace,
		},
	}

	// Checking if there is a Job Resource by Name
	err := r.Client.Get(ctx,
		client.ObjectKey{Name: jobname, Namespace: namespace},
		&job)

	// Delete it if there is an old job resource
	fg := metav1.DeletePropagationBackground
	if err == nil {
		r.Client.Delete(ctx,
			&job, &client.DeleteOptions{PropagationPolicy: &fg})
	}

	apiConfigMapVolumeName := "api-cm-volume"
	ttlSecondsAfterFinished := int32(3600)

	jobToCreate := batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			Name:      jobname,
			Namespace: namespace,
		},
		Spec: batchv1.JobSpec{
         // We ensure that Jobs objects are garbaged collected after 1 hour
			TTLSecondsAfterFinished: &ttlSecondsAfterFinished,
			Template: corev1.PodTemplateSpec{
				Spec: corev1.PodSpec{
               // We don't want to restart the job if it fails
					RestartPolicy: "Never",
					Containers: []corev1.Container{
						{
							Name:    jobname,
							Image:   "quay.io/change-metrics/monocle:1.8.0",
							Command: []string{"bash"},
							Args:    []string{"-c", " monocle janitor update-idents --elastic ${MONOCLE_ELASTIC_URL} --config /etc/monocle/config.yaml"},
							Env: []corev1.EnvVar{
								elasticUrlEnvVar,
							},
							VolumeMounts: []corev1.VolumeMount{
								{
									Name:      apiConfigMapVolumeName,
									ReadOnly:  true,
									MountPath: "/etc/monocle",
								},
							},
						},
					},
					Volumes: []corev1.Volume{
						{
							Name: apiConfigMapVolumeName,
							VolumeSource: corev1.VolumeSource{
								ConfigMap: &corev1.ConfigMapVolumeSource{
									LocalObjectReference: corev1.LocalObjectReference{
										Name: apiConfigMapName,
									},
								},
							},
						},
					},
				},
			},
		},
	}
	if err := ctrl_util.SetControllerReference(&instance, &jobToCreate, r.Scheme); err != nil {
		logger.Info("Unable to set controller reference", "name", jobname)
	}

	return r.Create(ctx, &jobToCreate)
}
```

Key points here are:

- We first check for an existing job and delete it if it exists. This ensures that we only run
  one job at a time.
- We set a [job TTL][k8s-jobs-ttl] to ensure that the Job Resource and decendents are deleted.

To observe the behavior, just edit the `config.yaml` key of the `ConfigMap` to define
a crawler config in the demo `workspace` and see the job's logs.

```bash
$ kubectl get jobs
NAME                COMPLETIONS   DURATION   AGE
update-idents-job   1/1           6s         21s
$ kubectl get pods
NAME                                      READY   STATUS      RESTARTS   AGE
monocle-sample-api-c75dcc789-gmwwm        1/1     Running     0          163m
monocle-sample-crawler-867888fb8c-95jgt   1/1     Running     0          163m
monocle-sample-elastic-0                  1/1     Running     0          3h1m
update-idents-job-t7vgh                   0/1     Completed   0          9s
$ kubectl logs update-idents-job-t7vgh
2023-03-08 13:57:52 INFO    Monocle.Backend.Janitor:48: Janitor will process changes and event {"workspace":"demo","changes":285,"events":8670}
2023-03-08 13:57:52 INFO    Monocle.Backend.Janitor:50: Updated changes {"count":0}
2023-03-08 13:57:52 INFO    Monocle.Backend.Janitor:52: Updated events {"count":0}
2023-03-08 13:57:52 INFO    Monocle.Backend.Janitor:54: Author cache re-populated with entries {"count":60}
```

## How to test the Operator


## How to deploy the operator in production

## To conclude and more reading

Ideas for later:

- Adding a MonocleCrawler Custom Resource.
- How to ensure secrets are preserve

The [operator pattern white paper][operator-whitepaper].

[operator pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
[operator-phases]: https://operatorframework.io/operator-capabilities/
[operator SDK]: https://sdk.operatorframework.io/
[operator-sdb-layout]: https://master.sdk.operatorframework.io/docs/overview/project-layout/
[Monocle]: https://change-metrics.io
[Operator Hub]: https://operatorhub.io
[custom resource]: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
[custom resource definition]: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions
[Operator framework project]: https://operatorframework.io/
[sdk-create-api]: https://sdk.operatorframework.io/docs/cli/operator-sdk_create_api/
[sdk-init]: https://sdk.operatorframework.io/docs/cli/operator-sdk_init/
[go operator sdk]: https://sdk.operatorframework.io/docs/building-operators/golang/quickstart/
[controller-runtime]: https://pkg.go.dev/sigs.k8s.io/controller-runtime
[controller-runtime reconcile]: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile
[controller-runtime controller]: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Controllers
[controller-runtime manager]: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Managers
[kustomize]: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
[operator-whitepaper]:https://github.com/cncf/tag-app-delivery/blob/eece8f7307f2970f46f100f51932db106db46968/operator-wg/whitepaper/Operator-WhitePaper_v1-0.md
[monocle-compose]: https://github.com/change-metrics/monocle/blob/master/docker-compose.yml
[monocle-readme]: https://github.com/change-metrics/monocle#readme
[monocle-secrets]: https://github.com/change-metrics/monocle#environment-variables
[monocle-config]: https://github.com/change-metrics/monocle#configuration-file
[monocle-identities]: https://github.com/change-metrics/monocle#apply-idents-configuration
[controller-runtime-reconcile]: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile#Reconciler
[controller-runtime-req]: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile#Request
[k8s-statefulset]: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
[k8s-secret]: https://kubernetes.io/docs/concepts/configuration/secret/
[k8s-core-secret]: https://pkg.go.dev/k8s.io/api/core/v1#Secret
[controller-runtime-client]: https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/client
[k8s-config-map]: https://kubernetes.io/docs/concepts/configuration/configmap/
[k8s-core-configmap]: https://pkg.go.dev/k8s.io/api/core/v1#ConfigMap
[k8s-deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[k8s-core-deployment]: https://pkg.go.dev/k8s.io/api@v0.26.2/apps/v1#Deployment
[k8s-service]: https://kubernetes.io/docs/concepts/services-networking/service/
[k8s-core-service]: https://pkg.go.dev/k8s.io/api/core/v1#Service
[k8s-deployment-rollout]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment
[k8s-owner-reference]: https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/
[k8s-liveness-probes]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
[k8s-config-map-volume]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-volume
[k8s-secrets-as-env-vars]: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#configure-all-key-value-pairs-in-a-secret-as-container-environment-variables
[monocle-controller]: https://github.com/change-metrics/monocle-operator/blob/21b6403c3a3ad4830892cc05257f397a3732ad72/controllers/monocle_controller.go
[controller-runtime-owns]: https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/builder#Builder.Owns
[k8s-jobs]: https://kubernetes.io/docs/concepts/workloads/controllers/job/
[k8s-core-jobs]: https://pkg.go.dev/k8s.io/api/batch/v1#Job
[k8s-jobs-ttl]: https://kubernetes.io/docs/concepts/workloads/controllers/job/#ttl-mechanism-for-finished-jobs