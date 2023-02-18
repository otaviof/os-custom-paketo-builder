# OpenShift `BuildConfig`

The `BuildConfig` in this directory contains a example of using the `Custom` strategy to build a [Node.js application][nodejsExRepo] using the Buildpacks CNB (Paketo) in this repository.

In order to push the container image, the secret defined on the `BuildConfig`'s `.spec.output.pushSecret` must be created, i.e.:

```bash
oc create secret docker-registry internal-registry \
	--docker-server="image-registry.openshift-image-registry.svc:5000" \
	--docker-username="kubeadmin" \
	--docker-password="$(oc whoami --show-token)"

```

Including the `ImageStream` creation:

```bash
oc create imagestream nodejs-ex
```

The CNB must run as a non-privileged user, therefore add `anyuid` SCC to the respective service-account:

```bash
oc adm policy add-scc-to-user anyuid --serviceaccount=default && \
	oc adm policy add-scc-to-user anyuid --serviceaccount=default
```

The `anyuid` SCC takes place in combination with the `BUILD_PRIVILEGED` environment variable which effectively allows the POD to run with a non-privileged user.

Next, you can apply the `BuildConfig` resource:

```bash
oc apply --filename=os/buildconfig.yaml
```

Finally, start the build:

```bash
oc start-build nodejs-ex --follow --wait
```

[nodejsExRepo]: https://github.com/otaviof/nodejs-ex