Monocle Operator - Phase 1 - Basic Install
##########################################

:date: 2023-03-10
:category: blog
:authors: Fabien Boucher and Fransisco De Seruca Salgado

.. raw:: html

   <style type="text/css">

     .literal {
       border-radius: 6px;
       padding: 1px 1px;
       background-color: rgba(27,31,35,.05);
     }

   </style>

This post aims to explain how we built a k8s Operator using the
`operator SDK`_ for the `Monocle`_ project.

We used the opportunity of ``Monocle``, which is a quite simple project
in terms of architecture and workflows, to experiment with the k8s's
`operator pattern`_ and the ``operator SDK``.

We started that work based on limited knowledges about the k8s and
especially the Operator pattern, so this blog post also serves the
purpose of sharing our understanding from a novice perspective.

We'll cover the following topics:

-  What is a k8s Operator
-  How to create the project skeleton
-  Workflows related to the Monocle's operations
-  Handling Monocle' workflows with the operator
-  How to generate and deploy the operator

You can find the ``monocle-operator`` on this `github project`_.

.. _what-is-a-k8s-operator-:

What is a k8s Operator ?
========================

An `Operator`_ is a software capable of handling various operations
related to another software. The Operator handles operations usually
ensured by a SRE.

Handled operations are such as (but not limited to):

-  Deployment
-  (Re-)Configuration
-  Update
-  Scaling
-  Backup

Capabilities of an operator are split into `phases`_ as described in the
Operator framework documentation.

To create an Operator a developer needs to well understand how to
operate the target software.

A multitude of Operators for various softwares are already available
especially on `Operator Hub`_ and `Red Hat Ecosystem Catalog`_

An Operator is designed to live inside a k8s or OpenShift cluster. The
operator uses k8s' resources (Deployment, ConfigMap, ...) to handle the
target software' operations. It manages at least one CR (`Custom
Resource`_) that is defined by a CRD (`Custom Resource Definition`_) and
controlled by a `Custom Controller`_.

A Custom Controller watches for CR instances and ensures that k8s'
resources needed by the CR' instances are spawned and fully functional.
The controller runs continuously and reacts to various events ensuring
the declared state of the software is maintained. This is called
"Reconciliation".

In this blog post we introduce an Operator for the Monocle software,
based on a Custom Resource and a Custom controller. The controller is
implemented in Go to benefit from well tested and documented libraries.

.. _how-to-create-the-project-skeleton-:

How to create the project skeleton ?
====================================

The `Operator framework project`_ provides a `SDK`_ to ease the
bootstrap and maintainance of an operator.

First install the `GO operator SDK`_:

.. code-block:: bash

   curl -OL https://github.com/operator-framework/operator-sdk/releases/download/v1.26.0/operator-sdk_linux_amd64
   mkdir -p ~/.local/bin && mv operator-sdk_linux_amd64 ~/.local/bin/operator-sdk && chmod +x ~/.local/bin/operator-sdk

`Initialise your repository`_ using the ``init`` sub command:

.. code-block:: bash

   mkdir monocle-operator && cd monocle-operator
   git init .
   operator-sdk init --repo github.com/change-metrics/monocle-operator --owner "Monocle developers" --domain monocle.change-metrics.io
   git diff
   git add -A . && git commit -m"Init the operator"

Then, `add the new API`_ (a CRD) and a controller for the new
``Monocle`` Custom Resource:

.. code-block:: bash

   operator-sdk create api --group monocle --version v1alpha1 --kind Monocle --resource --controller
   git status
   git diff
   git add -A . && git commit -m"Add skeleton code for the Monocle CR"

If the Operator handles more that one CR then run the previous command
with the new ``Kind``.

The SDK for a `GO operator`_ generates the project code structure
composed of various files and directories. Check the `layout details
here`_.

We can see that an Operator is, at least defined, by the following
resources:

-  A `manager`_ and a set of `controllers`_
-  A set of `CRDs`_
-  A container image capable of running the ``manager``
-  A suite of YAML manifests to apply to the Kubernetes cluster to
   deploy the operator

From there we are ready to write the Monocle Operator.

Workflows related to the Monocle's operations
=============================================

An operator handles various workflows for the targeted software. Thus,
as a first step we need to identify exactly what are those workflows and
what they involve.

For our ``Phase 1`` journey we'd like to handle the deployment and the
configuration of Monocle. It is important to have a minimum
understanding of the software we intent to create an operator for. Feel
free to read the `Monocle's README file`_.

Deployment
----------

A minimal Monocle deployment is composed of three services. The upstream
project provides a `Docker Compose file`_ that we will replicate.

The database (ElasticSearch)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Monocle needs to get access to an ElasticSearch instance:

-  The service needs a storage for its indices.
-  We can use the upstream ElasticSearch container image.
-  We can rely on the minimal and default settings.

The Monocle API (serve the API and the WEB UI)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  The upstream project provides a container image.
-  The service is stateless.
-  The service connects to the database.
-  A configuration file is needed.
-  Some environment variables must be exposed (especially for the
   secrets).

The Monocle crawler
~~~~~~~~~~~~~~~~~~~

The crawler requires the same as the API, except that the service
connects to the API service (not to the database).

Configuration
-------------

Here we need to determine how an User will interact with the Monocle
Operator in order to change the Monocle configuration.

Update secrets
~~~~~~~~~~~~~~

The `secrets`_ hosts sensitive information used by the API and the
crawler processes (Code Review provider's API tokens, OpenID Token,
...). Any changes to the ``secrets`` require an API and crawler
processes restart.

.. _update-configyaml:

Update config.yaml
~~~~~~~~~~~~~~~~~~

The `config file`_ is used by the API and the crawler. Monocle is able
to detect changes in its configuration file and apply configuration
updates automatically.

The ``janitor update-idents`` command must be run in case of updating
the ``config file`` to `update identities`_.

Handling Monocle's workflows with the Operator
==============================================

As we know better about workflows we need to implement inside our
Monocle controller we can start to implement it. We'll just explain some
code blocks.

Feel free to refer to the `complete controller code`_.

The reconcile loop
------------------

The operator SDK generated an empty Monocle's ``Reconcile`` function.

This function aims to make the requested state (by applying the
``Monocle`` resource) to be the state into the cluster. When a
``Monocle`` resource is applied to the cluster we want to provide a
working Monocle deployment with the database, the api, and the crawler.

Furthermore various attributes can be configured into the ``spec`` (see
``api/v1alpha1/monocle_types.go``\ `monocle-types`_) via the CRD so we
need to get the instance's ``spec`` to gather all information about the
expected state.

The Monocle CRD is autogenerated from the `monocle go types`_ by the SDK
(``make manifests``). Here you can see the `Monocle CRD`_.

To do so we write the function in order to get the Monocle instance
Resource according to the `req`_ content:

.. code-block:: Go

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

This ``Reconcile`` function is called every time an event occurs on a
Monocle instance such as by an apply or an update:

.. code-block:: bash

   $ kubectl apply -f config/samples/monocle_v1alpha1_monocle.yaml
   $ kubectl edit Monocle monocle-sample

The ``operator-sdk create api`` created a default
``config/samples/monocle_v1alpha1_monocle.yaml`` file that we can use to
reclaim an instance of ``Monocle``.

Based on that minimal ``Reconcile`` function implementation we can
experiment:

Start the manager in dev mode:

.. code-block:: bash

   $ make run
   # or
   $ go run ./main.yaml

In another terminal you can ``apply`` the resource with:

.. code-block:: bash

   $ kubectl apply -f config/samples/monocle_v1alpha1_monocle.yaml

Then the ``Monocle's controller`` should display and stop the reconcile
loop:

.. code-block:: bash

   1.6781911388888087e+09  INFO    controller-runtime.metrics      Metrics server is starting to listen    {"addr": ":8080"}
   ...
   1.6781911390910478e+09  INFO    Starting workers        {"controller": "monocle", "controllerGroup": "monocle.monocle.change-metrics.io", "controllerKind": "Monocle", "worker count": 1}
   1.6781911505580697e+09  INFO    Found Monocle object.   {"controller": "monocle", "controllerGroup": "monocle.monocle.change-metrics.io", "controllerKind": "Monocle", "Monocle": {"name":"monocle-sample","namespace":"fbo"}, "namespace": "fbo", "name": "monocle-sample", "reconcileID": "580d1b93-e4d8-41ef-8996-817e198727ff"}

You can observe that the ``controller`` re-enters the reconcile loop
when we edit the Monocle instance:

.. code-block:: bash

   # Add a new label in metadata.labels and save.
   $ kubectl edit monocle monocle-sample

The return value of the reconcile function controls how the
``controller`` re-enter it. See `details here`_.

Next steps are to handle the deployment of the services that compose a
Monocle deployment.

How the operator starts Monocle' components
-------------------------------------------

We'll only focus on the ``api`` service in that section. Other services
are pretty similar except the database service that is deployed via the
`StatefulSet`_.

Feel free to refer to the `complete controller code`_.

The API secret
~~~~~~~~~~~~~~

The ``Monocle`` API service needs to access some secrets data. Here we
use the `Secret`_ resource to store this data.

The Monocle's controller needs to:

-  Check if the secret exist
-  Create the secret resource if it does not exist
-  Continue if it exists

The ``secret`` is identified by its name and as a good practice
Resource's names must be unique in a single ``namespace``.

Here is how we handle the ``secret`` resource (`type`_):

.. code-block:: Go

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

As you can see, we check for the secret state and perform actions
according to the state. We use the `Client`_ exposed through the
``MonocleReconciler`` interface to perform CRUD actions.

This is a common pattern that we'll use for other resources managed by
the controller.

The API config
~~~~~~~~~~~~~~

The
`ConfigMap`_\ (`type <https://pkg.go.dev/k8s.io/api/core/v1#ConfigMap>`__)
are pretty similar regarding their API so the implementation is
equivalent as for the ``secret``.

.. code-block:: Go

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

For all resources created by the Monocle ``controller`` we set an
`OwnerReference`_. This ensures that when we delete the CR instance then
all dependents resources are also deleted. It serves also to the
``manager`` to call the reconcile function when a dependent resource is
updated.

The API deployment
~~~~~~~~~~~~~~~~~~

To run the API service we use the `Deployment
resource`_\ (`type <https://pkg.go.dev/k8s.io/api@v0.26.2/apps/v1#Deployment>`__)
and in front of it we configure a
`Service`_\ (`type <https://pkg.go.dev/k8s.io/api/core/v1#Service>`__)
resource.

A ``Deployment`` manages a set of ``Pods`` according to rules and
workflows implemented in the ``Deployment``'s controller.

``Pods`` can be spawned on different cluster's nodes, in which the node
will assign an IP address to each container within a pod. To tackle this
dynamic address assiging ``Service`` resource is needed on top of a
``Deployment``.

Let's start by creating the ``api-service`` resource:

.. code-block:: Go

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

Now let's see how the Monocle API is deployed. It leverages the
``Deployment`` resource to start a ``Pod`` containing one ``Monocle``
container based on the upstream container image.

.. code-block:: Go

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

   // We read the Monocle Public URL value passed via the CRD's spec
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
            // The Volume is the API ConfigMap that we expose as a volume.
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

Some key points that are important here:

-  The ``Deployment`` ensures that we always have a working ``Pod`` that
   serves the Monocle API.
-  The `liveness probe`_ is used by the ``Deployment`` to ensure the
   Monocle API is ready. The ``Deployment``'s status is based on the
   probe's status.
-  We expose the configuration file from a `ConfigMap`_ using a
   `volume`_. When the ``configMap``'s data is updated, the exposed
   files as volume's mount are automatically updated.
-  We expose the ``Secret`` resource containing Monocle' secrets `as
   environment variables`_.

Assuming that others Monocle' services are set up in the controller we
can inspect ``Resources`` spawned by the ``controller`` when we reclaim
a ``Monocle`` resource.

.. code-block:: bash

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

Accessing the Monocle WEB UI access served by the API can be locally
done using a ``port-forward``:

.. code-block:: bash

   $ kubectl port-forward service/monocle-sample-api 8090:8080
   $ firefox http://localhost:8090

How the operator handles Monocle' reconfigurations
--------------------------------------------------

Now let's see how we handled the (re-)configuration workflow.

As `described previously`_ we need to handle:

-  A change to the Monocle secrets (stored in a ``Secret`` resource)
   restarts the API and the Crawler ``Pods``.
-  A change to the Monocle config file (stored in a ``ConfigMap``
   resource) triggers the ``update-idents`` CLI command.

Handling Secret changes
~~~~~~~~~~~~~~~~~~~~~~~

API and Crawler processes are handled by the `Deployment Resource`_.
This resource's controller handles a `rollout`_ workflow when the
``podSpec``'s ``Image`` field or the ``podTemplateSpec``'s annotations
are updated. A ``rollout`` restarts ``Pods`` in safe manner according to
the configured rollout strategy.

To ensure that API and Crawlers containers are restarted when the
Monocle's administrator changes the secrets we use an annotation (we
only focus on the API, the same applies for the Crawler's Deployment):

.. code-block:: Go

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

.. code-block:: Go

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

At ``Deployment`` creation we set an annotation called:
``apiSecretsVersion``, and every time the ``Reconcile`` function is
called the ``rollOutWhenApiSecretsChange`` function checks if the
resource version changed. In the case of a change (meaning that the
administrator changed one of the Monocle's secrets) we do an ``Update``
of the annotation and store the new ``apiSecretsVersion`` value.

This triggers the ``Deployments`` rollout process, where the current
containers in a ``Pod`` are terminated and the new ones are created. In
this case with the ``apiSecretsVersion`` annotation value updated.

This can be observed by editing secrets to add a new one, then ensuring
pods are re-spawned and that the new secret is available in the ``env``
of the pod's container:

.. code-block:: bash

   # A secret value must be encoded as base64
   $ kubectl edit secrets monocle-sample-api
   $ kubectl get pods
   $ kubectl exec -it monocle-sample-api-c75dcc789-gmwwm -- env | grep -i <new-secret>

To configure the controller to call the ``Reconcile`` function when a
dependent resource is changed, we need to sets up the `Manager`_ this
way:

.. code-block:: Go

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

The `Owns`_ coupled to the `owner references`_ ensure that the
``Reconcile`` function is called when a dependent resource is updated.

Handling Config changes
~~~~~~~~~~~~~~~~~~~~~~~

The ``ConfigMap`` that stores the Monocle's config ``config.yaml`` is
exposed as a ``Volume Mount`` in ``/etc/monocle`` and Monocle knows how
to reload itself when its file is changed.

However we still need to detect updates on the ``ConfigMap`` and start a
Monocle's CLI command to `update idents`_. To do that we use a `Job`_
Resource (`type <https://pkg.go.dev/k8s.io/api/batch/v1#Job>`__).

The ``Job`` starts a ``Pod`` and reports execution status of the
container's command.

Similarly to the Monocle secrets, we store, in an annotation
(``apiConfigVersion``) on the API ``Deployment`` resource, the
``ResourceVersion`` of the ``ConfigMap`` and by checking for a version
change we can create a ``Job`` resource and trigger the CLI command.

.. code-block:: Go

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

.. code-block:: Go

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
                               Args:    []string{"-c", "monocle janitor update-idents --elastic ${MONOCLE_ELASTIC_URL} --config /etc/monocle/config.yaml"},
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

Key points here are:

-  We first check for an existing job (with the same name) and delete it
   if exists. This ensures that we only run one job at a time.
-  We set a `job TTL`_ to ensure that the Job Resource and its
   decendents are deleted to avoid leftovers.

To observe that behavior, just edit the ``config.yaml`` key of the
``ConfigMap`` to define a crawler's config in the ``demo`` ``workspace``
and see the job's logs.

.. code-block:: bash

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

How to generate and deploy the operator
=======================================

The Monocle project publishes and maintains the `operator image`_ in his
quay.io organisation and provides in the ``install`` directory two yaml
files to install:

-  the CRDs: ``crd.yml``
-  the required Resources defintion to install the operator:
   ``operator.yml``.

The installation is as simple as:

.. code-block:: bash

   $ kubectl apply -f install/crds.yml
   $ kubectl apply -f install/operator.yml

Both commands, above, require the ``cluster-admin`` role.

The operator is installed into a dedicated namespace
``monocle-operator-system``.

The ``operator.yml`` takes care of creating:

-  the operator's **Namespace** ``monocle-operator-system``
-  the **Service Account** ``monocle-operator-controller-manager`` into
   the namespace
-  the **ClusterRole** ``monocle-operator-manager-role``. This role
   defines `authorizations`_ needed by the ``controller`` to act on the
   cluster's API. Authorizations are handled by the operator SDK through
   the `kubebuilder markers system`_.
-  the **ClusterRole** ``monocle-operator-monocle-editor-role`` which
   can be assigned to a User to give authorisation to manipulate Monocle
   instances (CR).
-  the **ClusterRoleBinding** ``monocle-operator-manager-rolebinding``
   that allows the ``monocle-operator-controller-manager`` Service
   Account to act upon the resources.
-  the **Deployment** ``monocle-operator-controller-manager`` which runs
   the operator's image.

You can see if the deployment is successful by running the following
command:

.. code-block:: bash

   $ kubectl -n monocle-operator-system get all
   NAME                                                      READY   STATUS    RESTARTS   AGE
   pod/monocle-operator-controller-manager-b999fdcc8-cxjkn   2/2     Running   0          32s

   NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
   deployment.apps/monocle-operator-controller-manager   1/1     1            1           32s

   NAME                                                            DESIRED   CURRENT   READY   AGE
   replicaset.apps/monocle-operator-controller-manager-b999fdcc8   1         1         1       32s

and verify logs of the ``monocle-operator-controller-manager`` pod:

.. code-block:: bash

   $ kubectl -n monocle-operator-system logs deployment.apps/monocle-operator-controller-manager
   ...
   1.6784568095333292e+09  INFO    Starting EventSource    {"controller": "monocle", "controllerGroup": "monocle.monocle.change-metrics.io", "controllerKind": "Monocle", "source": "kind source: *v1.StatefulSet"}
   1.678456809533342e+09   INFO    Starting EventSource    {"controller": "monocle", "controllerGroup": "monocle.monocle.change-metrics.io", "controllerKind": "Monocle", "source": "kind source: *v1.Service"}
   1.6784568095333524e+09  INFO    Starting Controller     {"controller": "monocle", "controllerGroup": "monocle.monocle.change-metrics.io", "controllerKind": "Monocle"}
   1.678456809634908e+09   INFO    Starting workers        {"controller": "monocle", "controllerGroup": "monocle.monocle.change-metrics.io", "controllerKind": "Monocle", "worker count": 1}

How to start a Monocle instance
-------------------------------

A Monocle instance can be reclaimed to the operator by applying the
``Sample`` resource:

.. code-block:: bash

   $ kubectl apply -f config/samples/monocle_v1alpha1_monocle-alt.yaml
   $ kubectl get monocle monocle-sample -o yaml
   apiVersion: monocle.monocle.change-metrics.io/v1alpha1
   kind: Monocle
   metadata:
     creationTimestamp: "2023-03-10T14:20:24Z"
     generation: 1
     labels:
       app.kubernetes.io/created-by: monocle-operator
       app.kubernetes.io/instance: monocle-sample
       app.kubernetes.io/managed-by: kustomize
       app.kubernetes.io/name: monocle
       app.kubernetes.io/part-of: monocle-operator
     name: monocle-sample
     namespace: dev-admin
     resourceVersion: "326755"
     uid: 4b72edc4-1192-4369-9348-2a669ae4d65d
   spec:
     monoclePublicURL: http://localhost:8090
   status:
     monocle-api: Ready
     monocle-crawler: Ready
     monocle-elastic: Ready

How to generate the operator
----------------------------

The operator is composed of:

-  the operator container image
-  some Kubernetes Resources to enable its installation into a cluster

The operator SDK provides the tooling to generate the operator image via
the Makefile:

.. code-block:: bash

   $ make docker-build
   $ # or
   $ make container-build

The generated image can be found locally and then can be pushed to the
image registry via:

.. code-block:: bash

   $ make docker-push
   $ # or
   $ make container-push

For Monocle we have created an additional ``Makefile`` target:

.. code-block:: Makefile

   # Generate the install/operator.yml and install/crds.yml
   .PHONY: gen-operator-install
   gen-operator-install: manifests kustomize
       cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
       $(KUSTOMIZE) build config/operator > install/operator.yml
       $(KUSTOMIZE) build config/crd > install/crds.yml

This generates two ``manifests`` files needed to install the Monocle
operator by relying on the `kustomize`_ tool and provisionned (by the
operator SDK) configs stored into ``/config``.

To conclude
===========

It was our first attempt working with Kubernetes Operators, at first we
were astonished with the quantity of information and tools there are to
start developing an Operator like `kubebuiler`_ and `operator SDK`_.
Then deciding which stack to use for the operator's development `helm`_,
`ansible`_ or `go`_, and at the same time learning new things and
finding out how Kubernetes works in more detail every day.

It was a great and challenging oportunity to learn this big new world of
Kubernetes, and we hope to have made the right choices for the
continuity of Monocle Operator.

Stay tuned for the next posts, where we will continue in this exciting
new world of Operators. Fell free to talk to us.

Thank you hanging with us.

.. _operator SDK: https://sdk.operatorframework.io/
.. _Monocle: https://changemetrics.io
.. _operator pattern: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
.. _github project: https://github.com/change-metrics/monocle-operator/tree/813eb65df2da2249a5f2f0dd348ac4a3b6f11f0c
.. _Operator: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
.. _phases: https://operatorframework.io/operator-capabilities/
.. _Operator Hub: https://operatorhub.io
.. _Red Hat Ecosystem Catalog: https://catalog.redhat.com/software/search?deployed_as=Operator
.. _Custom Resource: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
.. _Custom Resource Definition: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions
.. _Custom Controller: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#custom-controllers
.. _Operator framework project: https://operatorframework.io/
.. _SDK: https://sdk.operatorframework.io/
.. _GO operator SDK: https://sdk.operatorframework.io/docs/installation/
.. _Initialise your repository: https://sdk.operatorframework.io/docs/cli/operator-sdk_init/
.. _add the new API: https://sdk.operatorframework.io/docs/cli/operator-sdk_create_api/
.. _GO operator: https://sdk.operatorframework.io/docs/building-operators/golang/quickstart/
.. _layout details here: https://master.sdk.operatorframework.io/docs/overview/project-layout/
.. _manager: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Managers
.. _controllers: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Controllers
.. _CRDs: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions
.. _Monocle's README file: https://github.com/change-metrics/monocle#readme
.. _Docker Compose file: https://github.com/change-metrics/monocle/blob/master/docker-compose.yml
.. _secrets: https://github.com/change-metrics/monocle#environment-variables
.. _config file: https://github.com/change-metrics/monocle#configuration-file
.. _update identities: https://github.com/change-metrics/monocle#apply-idents-configuration
.. _complete controller code: https://github.com/change-metrics/monocle-operator/blob/813eb65df2da2249a5f2f0dd348ac4a3b6f11f0c/controllers/monocle_controller.go
.. _monocle-types: https://github.com/change-metrics/monocle-operator/blob/813eb65df2da2249a5f2f0dd348ac4a3b6f11f0c/api/v1alpha1/monocle_types.go
.. _monocle go types: https://github.com/change-metrics/monocle-operator/blob/813eb65df2da2249a5f2f0dd348ac4a3b6f11f0c/api/v1alpha1/monocle_types.go
.. _Monocle CRD: https://github.com/change-metrics/monocle-operator/blob/813eb65df2da2249a5f2f0dd348ac4a3b6f11f0c/config/crd/bases/monocle.monocle.change-metrics.io_monocles.yaml
.. _req: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile#Request
.. _details here: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile#Reconciler
.. _StatefulSet: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
.. _Secret: https://kubernetes.io/docs/concepts/configuration/secret/
.. _type: https://pkg.go.dev/k8s.io/api/core/v1#Secret
.. _Client: https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/client
.. _ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
.. _OwnerReference: https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/
.. _Deployment resource: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
.. _Service: https://kubernetes.io/docs/concepts/services-networking/service/
.. _liveness probe: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
.. _volume: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-volume
.. _as environment variables: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#configure-all-key-value-pairs-in-a-secret-as-container-environment-variables
.. _described previously: #configuration
.. _Deployment Resource: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
.. _rollout: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment
.. _Manager: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Managers
.. _Owns: https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/builder#Builder.Owns
.. _owner references: https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/
.. _update idents: https://github.com/change-metrics/monocle#apply-idents-configuration
.. _Job: https://kubernetes.io/docs/concepts/workloads/controllers/job/
.. _job TTL: https://kubernetes.io/docs/concepts/workloads/controllers/job/#ttl-mechanism-for-finished-jobs
.. _operator image: https://quay.io/repository/change-metrics/monocle-operator
.. _authorizations: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole
.. _kubebuilder markers system: https://book.kubebuilder.io/reference/markers/rbac.html
.. _kustomize: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
.. _kubebuiler: https://kubebuilder.io/
.. _helm: https://sdk.operatorframework.io/docs/building-operators/helm/tutorial/
.. _ansible: https://sdk.operatorframework.io/docs/building-operators/ansible/tutorial/
.. _go: https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/
