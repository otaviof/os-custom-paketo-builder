# OpenShift Build

The `BuildConfig` in this directory contains a example of using the `Custom` strategy to build a [Node.js application][nodejsExRepo] using the Buildpacks CNB (Paketo) in this repository.

First, create the `ImageStreams` repository, with:

```bash
oc create imagestream nodejs-ex
```

In order to push the container image, the secret defined on the `BuildConfig`'s `.spec.output.pushSecret` must be created with the `config.json` key. Later the secret is mounted on the building POD thus buildpack CNB will be able to find the expected file, to create the secret name `imagestreams` run:

```bash
REGISTRY_HOSTNAME="image-registry.openshift-image-registry.svc:5000" \
REGISTRY_USERNAME="kubeadmin" \
REGISTRY_PASSWORD="$(oc whoami --show-token)" \
	oc create secret generic imagestreams \
		--from-literal=config.json="{\"auths\":{\"${REGISTRY_HOSTNAME}\":{\"username\":\"${REGISTRY_USERNAME}\",\"password\":\"${REGISTRY_PASSWORD}\"}}}"
```

Add the `anyuid` SCC to your respective service-account, the CNB must run as a non-privileged user.

```bash
oc adm policy add-scc-to-user anyuid --serviceaccount=default && \
	oc adm policy add-scc-to-user anyuid --serviceaccount=default
```

The `anyuid` SCC takes place in combination with the `BUILD_PRIVILEGED` environment variable to effectively allows the POD to run with a non-privileged user (1000). Next, you can apply the `BuildConfig` resource:

```bash
oc apply --filename=os/buildconfig.yaml
```

Finally, start the build:

```bash
oc start-build nodejs-ex --follow --wait
```

## Deploying

Rolling out the application in OpenShift can be achieved with the following commands:

```bash
oc new-app nodejs-ex:latest
oc expose deployment nodejs-ex --port=8080 --target-port=8080
oc expose service nodejs-ex
```

Next, get the route created for the application:

```bash
oc get routes nodejs-ex
```

And try to reach its endpoint, for instance:

```bash
curl http://nodejs-ex-otaviof.apps-crc.testing
```

At the end you can remove everything with:

```bash
oc delete all --selector="app=nodejs-ex"
oc delete imagestreams nodejs-ex
```

[nodejsExRepo]: https://github.com/otaviof/nodejs-ex