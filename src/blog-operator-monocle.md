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
a CRD ([Custom Resource Defintion][custom resource definition]) and a Custom Controller by CR.

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

The SDK for a [GO operator][go operator SDK] generates the project code structure composed of:

- A PROJECT file that describes the managed's (by the SDK) operator
- A Makefile. It handles various tasks such as:
   - CRD Yaml definition based on Go types, Roles definition based on code markers
   - operator code lint
   - operator start in developement mode
   - operator image build and publish
   - operator deployment
   - generate OLM bundle
- A Dockerfile used to build the operator container image
- Go code skeleton based on the [controller-runtime library][controller-runtime]:
   - main.go: The entry point that defines the controler-runtime's manager and start the CR's controller.
   - controllers/\<cr-name\>_controller.go: The controller code skeleton,
   including the [reconcile loop][controller-runtime reconcile] function.
   - controllers/suite_test.go: A test suite skeleton
   - api/\<api-version\>/\<cr-name\>_types.go: The Custom Resource Definition (the spec and the status).
- YAML files:
   - config/crd: the auto-generated CRD yaml file
   - config/manager: the auto-generated YAML that define the operator's manage deployment,
   and namespace
   - config/rbac: Auto-generated Role Based Access Control defintions
      - service_account.yaml: The service account that the operator will use to act on the
         k8s's API.
      - role.yaml: Defines the `manager-role` role which define authorized actions on our
      new controller's resources.
      - role_binding.yaml: Binds the service account to the `manager-role`.
      - leader_election_role_(binding).yaml: Enables use of leaders related resources for the
         service account.
      - \<cr-name\>-(viewer|editor)_role.yaml: Roles to allow users to read or edit the Custom Resource.
   - config/sample: a ready to use YAML to deploy our new CR
   - default/kustomization.yaml: The entrypoint of the [kustomize][kustomize] configuration for YAML generations.

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
processes (Code Review provider's API tokens, OpenID Token, ...). Any changes on
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
in the cluster. When a `Monocle` resource exist we want to provide a working Monocle deployment
with the database, the api, and the crawler.

Furthermore various attributes can configured in the `spec` (see `api/v1alpha1/monocle_types.go`)
and we need to get the instance's `spec` to get all information about the expected state.

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

This `Reconcile` function is called by the `manager` each time an event occurs on Monocle instance (a Monocle
instance is a Monocle spawned by the operator).

The `operator-sdk create api` created a default `config/samples/monocle_v1alpha1_monocle.yaml` that we
can use to ask an instance the `Monocle` Custom Resource.

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



### How the operator handles Monocle' reconfigurations


## How to test the Operator


## How to deploy the operator in production

To see which manifest are deployed (`kubectl apply -f`) by make deploy run:

```bash
$ ./bin/kustomize build config/default
```

## To conclude and more reading

Ideas for later:

- Adding a MonocleCrawler Custom Resource.

The [operator pattern white paper][operator-whitepaper].

[operator pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
[operator-phases]: https://operatorframework.io/operator-capabilities/
[operator SDK]: https://sdk.operatorframework.io/
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