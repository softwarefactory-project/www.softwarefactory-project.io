This post aims to introduce the [Operator Lifecycle Management (OLM)][OLM] and how we integrated the [Monocle Operator][monocle-operator] as a OLM package into the [operatorhub.io][operatorhub-io] catalog.

This article is a follow up post of "[Monocle Operator - Phase 1 - Basic Install][monocle-operator-blog-part-1]".

## What is OLM

The Operator Lifecycle Management (OLM) is an approach to managing Kubernetes operators that simplifies their deployment, updating, and ongoing management throughout their lifecycle. By using OLM, development teams can deploy operators with confidence, knowing that they will be effectively and consistently managed across the entire cluster.

OLM is built around two main components:

- **Catalogs**: These are collections of Operators that can be installed on a Kubernetes cluster. Catalogs can be public or private, and can be hosted on container registries or Kubernetes clusters. Each Operator in a catalog has a corresponding manifest that describes its deployment, configuration, and management. Catalogs allow users to easily discover, install and upgrade Operators on their cluster.

- **The Operator Lifecycle Manager**: This is the control plane component of OLM that manages the installation, upgrade, and removal of Operators on a Kubernetes cluster. The Operator Lifecycle Manager is responsible for ensuring that Operators are deployed and managed according to their defined lifecycle. It monitors the status of Operators, handles upgrades and rollbacks, and ensures that dependencies between Operators are resolved correctly.

OLM can be seen as a Linux Package Manager like **DNF**, indeed:

- both package managers rely on a manifest to ensure proper installation and configuration of the package or Operator.
- OLM and DNF package managers ensure that dependencies are resolved and the component is deployed and managed according to its defined lifecycle.
- both systems offer a standardized approach to managing software components, improving system stability and efficiency.

Here is a [glossary][olm-glossary] of OLM terminology.

## OLM installation

The [operator-sdk][operator-sdk] tool provides a command to deploy OLM on a Kubernetes deployment. This command creates various k8s resources to spawn OLM components and associated roles, role bindinds, service users, ...

```shell
operator-sdk olm install
```

Note, that the Ansible role [ansible-microshift-role][ansible-microshift-role] provides an easy way to deploy a lightweight OpenShift environment (using [Microshift][microshift]) with OLM enabled.

This `operator-sdk` command creates two namespaces:

- **olm**: It contains the OLM system with the **catalog-operator**, **olm-operator** and the **packageserver** deployments.
- **operators**: It is the placeholder where one can subscribe to an operator.

```shell
kubectl -n olm get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
catalog-operator   1/1     1            1           17d
olm-operator       1/1     1            1           17d
packageserver      2/2     2            2           17d
```

From we will be able to extend our k8s by installing new operators.

## OLM usage

In order to learn more about OLM, we will deploy the [cert-manager operator][cert-manager operator] from OLM.


The OLM installation should come with a the **Community Operators** catalog installed:

```shell
kubectl -n olm get catalogsources operatorhubio-catalog
NAME                    DISPLAY               TYPE   PUBLISHER        AGE
operatorhubio-catalog   Community Operators   grpc   OperatorHub.io   17d

kubectl -n olm get -o json catalogsources operatorhubio-catalog | jq '.spec'
{
  "displayName": "Community Operators",
  "grpcPodConfig": {
    "securityContextConfig": "restricted"
  },
  "image": "quay.io/operatorhubio/catalog:latest",
  "publisher": "OperatorHub.io",
  "sourceType": "grpc",
  "updateStrategy": {
    "registryPoll": {
      "interval": "60m"
    }
  }
}
```

Then we can explore the catalog for available operators:

```shell
# There is more than 300 operators listed so let's grep for cert-manager
kubectl -n olm get packagemanifests | grep cert-manager
cert-manager                               Community Operators   17d
```

A **PackageManifest** resource describes the following:

- The name and versions of the package being managed.
- A description of the package and its features.
- The default channel and available channels through which different versions of the package can be installed.
- The latest version of the package available by channel (*currentCSV*).
- A list of all versions of the package available through each channel.
- A list of CRDs that are installed along with the package.
- A list of global configuration variables for the package.
- The package's installation process and any dependencies required.

The **PackageManifest** resource could be heavy to inspect, are some commands to help:

```shell
# Show the package provider
kubectl -n olm get -o json packagemanifests cert-manager | jq '.status.provider'
{
  "name": "The cert-manager maintainers",
  "url": "https://cert-manager.io/"
}

# Show availble channels for that package
kubectl -n olm get -o json packagemanifests cert-manager | jq '.status.channels[].name'
"candidate"
"stable"

# Show the default install channel of that package
kubectl -n olm get -o json packagemanifests cert-manager | jq '.status.defaultChannel'
"stable"

# Last version available (package head) in the stable channel
kubectl -n olm get -o json packagemanifests cert-manager | jq '.status.channels[] | select(.name == "stable") | .currentCSV'
"cert-manager.v1.11.0"

# Versions from the stable channel
kubectl -n olm get -o json packagemanifests cert-manager | jq '.status.channels[] | select(.name == "stable") | .entries'
[
  {
    "name": "cert-manager.v1.11.0",
    "version": "1.11.0"
  },
  {
    "name": "cert-manager.v1.10.2",
    "version": "1.10.2"
  },
  ...
]

# And finally, to show the CSV of the last stable version
kubectl -n olm get -o json  packagemanifests cert-manager | jq '.status.channels[] | select(.name == "stable") | .currentCSVDesc' | less
```

The **PackageManifest** is built from a list of [ClusterServiceVersion definition][cluster-service-version]. The **ClusterServiceVersion** resource define information that is required to run the Operator, like the RBAC rules it requires and which custom resources (CRs) it manages or depends on.

To install the **cert-manager** operator from the **stable** channel we need to create a [Subscription][olm-subscription]. It describes which channel of an operator package to subscribe to, and whether to perform updates automatically or manually.

Create the file *cert-manager.yaml*:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: my-cert-manager
  namespace: operators
spec:
  channel: stable
  name: cert-manager
  source: operatorhubio-catalog
  sourceNamespace: olm
  # By default is automatic upgrade plan
  # installPlanApproval: Manual
```

Then apply with:

```shell
# Apply the subscription
kubectl apply -f cert-manager.yaml

# Get the subscription
kubectl -n operators get sub
NAME                  PACKAGE            SOURCE                  CHANNEL
my-cert-manager       cert-manager       operatorhubio-catalog   stable

# Ensure the CSV is now available
kubectl -n operators get csv
NAME                       DISPLAY            VERSION   REPLACES                   PHASE
cert-manager.v1.11.0       cert-manager       1.11.0    cert-manager.v1.10.2       Succeeded
```

Note that an [InstallPlan][install-plan] resource has been created where you can inspect installation step on the operator. This resource should be inspected in case the requested operator failed to be installed, for instance when the `csv` resource has not been created.

```shell
kubectl -n operators describe installplan install-tkcrn
```

By default the `Subscription` set the `installPlanApproval` as automatic. However if you decide to set it as manual, when OLM detects a possible upgrade (because of a new version available in the `stable` channel), then the `InstallPlan` will need to be manually updated to approve the upgrade. The process is described [here][olm-manual-upgrade].


Beside the fact that the `cert-manager.v1.11.0` CSV phase if `Succeeded` we can verify that the `cert-manager` operator is running:

```shell
kubectl -n operators get all | grep cert-manager
pod/cert-manager-68c79ccf94-hkbp8                               1/1     Running   0          62m
pod/cert-manager-cainjector-86c79dd959-q6x2q                    1/1     Running   0          62m
pod/cert-manager-webhook-b685d8cd4-9q6jj                        1/1     Running   0          62m
service/cert-manager                                          ClusterIP   10.43.98.149    <none>        9402/TCP   63m
service/cert-manager-webhook                                  ClusterIP   10.43.18.198    <none>        443/TCP    63m
service/cert-manager-webhook-service                          ClusterIP   10.43.34.128    <none>        443/TCP    62m
deployment.apps/cert-manager                               1/1     1            1           62m
deployment.apps/cert-manager-cainjector                    1/1     1            1           62m
deployment.apps/cert-manager-webhook                       1/1     1            1           62m
replicaset.apps/cert-manager-68c79ccf94                               1         1         1       62m
replicaset.apps/cert-manager-cainjector-86c79dd959                    1         1         1       62m
replicaset.apps/cert-manager-webhook-b685d8cd4                        1         1         1       62m
```

The requested operator is installed in the same namespace than its `Subscription`.

We can also ensure that CRDs provided by the operator are available:

```shell
kubectl api-resources | grep cert-manager
challenges                                     acme.cert-manager.io/v1                      true         Challenge
orders                                         acme.cert-manager.io/v1                      true         Order
certificaterequests               cr,crs       cert-manager.io/v1                           true         CertificateRequest
certificates                      cert,certs   cert-manager.io/v1                           true         Certificate
clusterissuers                                 cert-manager.io/v1                           false        ClusterIssuer
issuers                                        cert-manager.io/v1                           true         Issuer
```

Finally, let's create a namespace and reclaim for an `Issuer` instance:

Create the file *issuer.yaml*:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: example-issuer
spec:
  selfSigned: {}
```

Then apply the resource in a new namespace:

```shell
kubectl ceate ns test-cert-manager

kubectl -n test-cert-manager apply -f issuer.yaml
issuer.cert-manager.io/example-issuer created

kubectl -n test-cert-manager get issuers
NAME             READY   AGE
example-issuer   True    7s
```

## Packaging Monocle for OLM

Recently we wrote an [Operator][monocle-operator] for the Monocle project and we were curious about how to leverage OLM to make it easily consumable.

An [operator.yaml][install-dir] file was generated by the `kustomize build config/default` and then it was possible to apply the Monocle CRD and *install* the various resources (namespace, serviceuser, roles, role bindings, deployments, ...) to get the operator running.

From there the process was to create the [bundle][glossary-bundle] (or a package) using the `Makefile`'s target `bundle`:

```shell
make bundle
```

This creates a directory `bundle` which contains some directories:

- *manifests*: containing mainly the CRD(s), and the ClusterServiceVersion.
- *metadata*: this is some annotations to describe the bundle.
- *tests/scorecard*: this describe various to be performed on the bundle.

And that's just it. However we would like to validate our bundle, to do so we need to perform the following steps.

First we need to build and publish the `bundle`'s container image, so the our `Makefile` provides a `bundle-build` target:

```shell
make bundle-build bundle-push
```

Then we can use the `operator-sdk run bundle` command to simulate an OLM flow:

- Create an `operator catalog` containing only our `bundle`
- Run a Pod to serve the new `catalog`
- Create a `CatalogSource` resource to make the new `catalog` available
- ...

```shell
kubectl create ns bundle-catalog-ns
oc adm policy add-scc-to-user privileged system:serviceaccount:bundle-catalog-ns:default
operator-sdk --verbose run bundle quay.io/change-metrics/monocle-operator-bundle:v0.0.1 --namespace bundle-catalog-ns --security-context-config restricted
```

## Monocle operator on OperatorHub.io

# More reading

Here are some useful links to help extend your understanding:

- https://docs.openshift.com/container-platform/4.12/operators/understanding/olm/olm-understanding-olm.html

[OLM]: https://olm.operatorframework.io/
[monocle-operator]: https://github.com/change-metrics/monocle-operator
[operatorhub-io]: https://operatorhub.io
[monocle-operator-blog-part-1]: https://www.softwarefactory-project.io/monocle-operator-phase-1-basic-install.html
[olm-glossary]: https://olm.operatorframework.io/docs/glossary/
[operator-sdk]: https://sdk.operatorframework.io/
[cert-manager operator]: https://operatorhub.io/operator/cert-manager
[ansible-microshift-role]: https://github.com/openstack-k8s-operators/ansible-microshift-role
[microshift]: https://github.com/openshift/microshift
[cluster-service-version]: https://docs.openshift.com/container-platform/4.12/operators/understanding/olm-common-terms.html#olm-common-terms-csv_olm-common-terms
[olm-subscription]: https://olm.operatorframework.io/docs/concepts/crds/subscription/
[install-plan]: https://olm.operatorframework.io/docs/concepts/crds/installplan/
[olm-manual-upgrade]: https://olm.operatorframework.io/docs/concepts/crds/subscription/#manually-approving-upgrades-via-subscriptions
[install-dir]: https://github.com/change-metrics/monocle-operator/tree/6b8a02f9087f83798f732ede85cbe35c0304cb58/install
[glossary-bundle]: https://olm.operatorframework.io/docs/glossary/#bundle