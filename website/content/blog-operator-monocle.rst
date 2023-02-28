Monocle Operator - Phase 1 - Basic Install
##########################################

:date: 2023-03-01
:category: blog
:authors: Fabien Boucher

.. raw:: html

   <style type="text/css">

     .literal {
       border-radius: 6px;
       padding: 1px 1px;
       background-color: rgba(27,31,35,.05);
     }

   </style>

This post aims to explains how we built a k8s Operator using the
`operator sdk`_ for the `Monocle`_ project. We'll cover the following
topics:

-  What is a k8s Operator
-  How to create the project skeleton
-  Workflows related to the Monocle's operations
-  Handling Monocle' workflows with the Operator
-  How to test the Operator
-  How to deploy the operator in production

.. _what-is-a-k8s-operator-:

What is a k8s Operator ?
========================

An `Operator`_ is a software capables of handling various operations
related to another software. The Operator handles operations usually
ensured by a SRE.

Handled operations are such as (but not limited to):

-  Deployment
-  Re-configuration
-  Update
-  Scaling
-  Backup

Capabilities of an operator are splitted in `phases`_ as described in
the Operator framework documentation.

To create an Operator a developer needs to well understand how to
operate the target software.

A multitude of Operators for various softwares are already available
especially on `Operator Hub`_.

An Operator is designed to live inside a k8s or OpenShift deployment.
The operator uses k8s' resources (Deployment, ConfigMap, ...) to handle
the target software' operations. It defines at least one CR (`Custom
Resource`_) that can be configured via a CRD (`Custom Resource
Definition`_) and a Custom Controller by CR.

A Custom Controller watches for instances of a CR and ensures that k8s'
resources needed by the CR's instance are spawned and fully functional.
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

Then, `add the new API`_ (a CRD) and a controller for the new Custom
Resource ``Monocle``:

.. code-block:: bash

   operator-sdk create api --group monocle --version v1alpha1 --kind Monocle --resource --controller
   git status
   git diff
   git add -A . && git commit -m"Add skeleton code for the Monocle CR"

If the Operator handles more CRs then run the previous command with the
new ``Kind``.

The SDK for a `GO operator`_ generates the project code structure
composed of:

-  A PROJECT file that describes the managed's (by the SDK) operator
-  A Makefile. It handles various tasks such as:

   -  CRD Yaml definition based on Go types, Roles definition based on
      code markers
   -  operator code lint
   -  operator start in developement mode
   -  operator image build and publish
   -  operator deployment
   -  generate OLM bundle

-  A Dockerfile used to build the operator container image
-  Go code skeleton based on the `controller-runtime library`_:

   -  main.go: The entry point that defines the controler-runtime's
      manager and start the CR's controller.
   -  controllers/<cr-name>_controller.go: The controller code skeleton,
      including the `reconcile loop`_ function.
   -  controllers/suite_test.go: A test suite skeleton
   -  api/<api-version>/<cr-name>_types.go: The Custom Resource
      Definition (the spec and the status).

-  YAML files:

   -  config/crd: the auto-generated CRD yaml file
   -  config/manager: the auto-generated YAML that define the operator's
      manage deployment, and namespace
   -  config/rbac: Auto-generated Role Based Access Control defintions

      -  service_account.yaml: The service account that the operator
         will use to act on the k8s's API.
      -  role.yaml: Defines the ``manager-role`` role which define
         authorized actions on our new controller's resources.
      -  role_binding.yaml: Binds the service account to the
         ``manager-role``.
      -  leader_election_role_(binding).yaml: Enables use of leaders
         related resources for the service account.
      -  <cr-name>-(viewer|editor)_role.yaml: Roles to allow users to
         read or edit the Custom Resource.

   -  config/sample: a ready to use YAML to deploy our new CR
   -  default/kustomization.yaml: The entrypoint of the `kustomize`_
      configuration for YAML generations.

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

For our ``Day 1`` journey we'd like to handle the deployment and the
configuration of Monocle. It is important to have a minimum
understanding of the software we intent to create an operator for so
feel free to read the `Monocle's README file`_.

Deployment
----------

A minimal Monocle deployment is composed of three services. The upstream
project provide a `Docker Compose recipe`_ that we will replicate.

The database (ElasticSearch)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Monocle needs to get access to an ElasticSearch instance:

-  The service needs a storage for its indices.
-  We can use the upstream ElasticSearch container image.
-  We can rely on the minimal and default settings.

The Monocle API (serve the API and the WEB UI)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  The upstream project provides a container image.
-  The service a stateless.
-  A configuration file is needed.
-  Some environment variables must be exposed (especially for the
   secrets).

The Monocle crawler
~~~~~~~~~~~~~~~~~~~

The crawler requires the same as the API.

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
to detect changes in its configuration file and reload the
configuration.

The ``janitor update-idents`` command must be run in case of updating
the ``config file`` to `update identities`_.

Handling Monocle' workflows with the Operator
=============================================

As we know better about workflow we need to implement inside our Monocle
controller we can start implementing. We'll just explain some code
blocks.

The reconcile loop
------------------

The operator SDK generated an empty Monocle's ``Reconcile`` function.

This function aims to make the requested state (by applying the
``Monocle`` resource) state in the cluster. When a ``Monocle`` resource
exist we want to provide a working Monocle deployment with the database,
the api, and the crawler.

Furthermore various attributes can configured in the ``spec`` (see
``api/v1alpha1/monocle_types.go``) so we need to get the instance's
``spec`` to gather all information about the expected state.

To do so we fill the function in order to get the Monocle instance
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

This ``Reconcile`` function is called by the ``manager`` each time an
event occurs on Monocle instance (a Monocle instance is a Monocle
spawned by the operator).

The ``operator-sdk create api`` created a default
``config/samples/monocle_v1alpha1_monocle.yaml`` file that we can use to
reclaim an instance the ``Monocle`` Custom Resource.

Start the manager in dev mode:

.. code-block:: bash

   $ make run
   # or go run ./main.yaml

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
are pretty similar expected the database service that is deployed via
the [StatefulSet][k8s-statefullset].

Feel free to refer to the `complete controller code`_.

The API secret
~~~~~~~~~~~~~~

The ``Monocle`` API service needs to access some secrets data. Here we
use the `secret`_ resource to store this data.

The Monocle's controller needs to:

-  Check if the secret exist
-  Create the secret resource if it does not exist
-  Continue if it exists

The ``secret`` is identified by its name and must be unique in the
``namespace``.

Here is how we handle the ``secret`` resource
([type][k8s-core-secrets]):

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

As you can see, the code detects the secret state and perform actions
according to the state. We use the `Client`_ exposed through the
``MonocleReconcilier`` interface to perform CRUD actions. This is a
common pattern that we'll use for other resources managed by the
controller.

The API config
~~~~~~~~~~~~~~

The `ConfigMap`_\ (`type`_) are pretty similar regarding their API so
the code below is the same as for the ``secret``.

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

For all resources created by the Monocle ``controller`` we set a
[OwnerReference][k8s-owner-references]. This ensures that when we delete
the CR instance then all dependents resources are also deleted. It
serves also to the ``manager`` to call the reconcile function when a
dependent resource is updated.

The API deployment
~~~~~~~~~~~~~~~~~~

To run the API service we use the `Deployment
resource`_\ (`type <https://pkg.go.dev/k8s.io/api@v0.26.2/apps/v1#Deployment>`__)
and in front of it we configure a
`Service`_\ (`type <https://pkg.go.dev/k8s.io/api/core/v1#Service>`__)
resource.

A ``Deployment`` manages a set of ``Pods`` according to rules and
workflows implemented in the ``Deployment``'s controller. For instance a
``Deployment`` can perform a `rollout`_ when the container's ``Image``
of the ``podSpec`` or the ``podTemplateSpec``'s annotations are updated.

A ``rollout`` restarts ``Pods`` in safe manner according to the
configured strategy.

As ``Pods`` can be spawned on different cluster' nodes then container'
IP addresses can change then a ``Service`` resource is needed on top of
a ``Deployment``.

Let's start by creating ``api-service`` resource:

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
           "apiConfigVersion": apiConfigVersion,
       }

       // Set the Deployment pod template
       apiDeployment.Spec.Template = corev1.PodTemplateSpec{
           ObjectMeta: metav1.ObjectMeta{
            // Enable relation between Pod, Deployment and Service
               Labels: apiMatchLabels,
            // Here we set the Resource version of the Monocle secrets
            // to enable rollout
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

Some key points that are important here:

-  The ``Deployment`` ensures that we always have a working ``Pod`` that
   serves the Monocle API.
-  The `liveness probe`_ is used by the ``Deployment`` to ensure the
   Monocle API is ready. The ``Deployment``'s status is based on the
   probe's status.
-  We expose the configuration file from a `ConfigMap`_ using a
   `volume`_. When the ``configMap``'s data is updated exposed files are
   updated on the volume mount.
-  We expose the ``Secret`` resource containing Monocle' secrets `as
   environment variables`_.

How the operator handles Monocle' reconfigurations
--------------------------------------------------

How to test the Operator
========================

How to deploy the operator in production
========================================

To see which manifest are deployed (``kubectl apply -f``) by make deploy
run:

.. code-block:: bash

   $ ./bin/kustomize build config/default

To conclude and more reading
============================

Ideas for later:

-  Adding a MonocleCrawler Custom Resource.

The `operator pattern white paper`_.

.. _operator sdk: https://sdk.operatorframework.io/
.. _Monocle: https://change-metrics.io
.. _Operator: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
.. _phases: https://operatorframework.io/operator-capabilities/
.. _Operator Hub: https://operatorhub.io
.. _Custom Resource: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
.. _Custom Resource Definition: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions
.. _Operator framework project: https://operatorframework.io/
.. _SDK: https://sdk.operatorframework.io/
.. _GO operator SDK: https://sdk.operatorframework.io/docs/building-operators/golang/quickstart/
.. _Initialise your repository: https://sdk.operatorframework.io/docs/cli/operator-sdk_init/
.. _add the new API: https://sdk.operatorframework.io/docs/cli/operator-sdk_create_api/
.. _GO operator: https://sdk.operatorframework.io/docs/building-operators/golang/quickstart/
.. _controller-runtime library: https://pkg.go.dev/sigs.k8s.io/controller-runtime
.. _reconcile loop: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile
.. _kustomize: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
.. _manager: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Managers
.. _controllers: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Controllers
.. _CRDs: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions
.. _Monocle's README file: https://github.com/change-metrics/monocle#readme
.. _Docker Compose recipe: https://github.com/change-metrics/monocle/blob/master/docker-compose.yml
.. _secrets: https://github.com/change-metrics/monocle#environment-variables
.. _config file: https://github.com/change-metrics/monocle#configuration-file
.. _update identities: https://github.com/change-metrics/monocle#apply-idents-configuration
.. _req: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile#Request
.. _details here: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile#Reconciler
.. _complete controller code: https://github.com/change-metrics/monocle-operator/blob/21b6403c3a3ad4830892cc05257f397a3732ad72/controllers/monocle_controller.go
.. _secret: https://kubernetes.io/docs/concepts/configuration/secret/
.. _Client: https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/client
.. _ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
.. _type: https://pkg.go.dev/k8s.io/api/core/v1#ConfigMap
.. _Deployment resource: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
.. _Service: https://kubernetes.io/docs/concepts/services-networking/service/
.. _rollout: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment
.. _liveness probe: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
.. _volume: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-volume
.. _as environment variables: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#configure-all-key-value-pairs-in-a-secret-as-container-environment-variables
.. _operator pattern white paper: https://github.com/cncf/tag-app-delivery/blob/eece8f7307f2970f46f100f51932db106db46968/operator-wg/whitepaper/Operator-WhitePaper_v1-0.md
