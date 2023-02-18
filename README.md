Buildpacks CNB for OpenShift `BuildConfigs`
-------------------------------------------

Custom Paketo based Buildpacks CNB for OpenShift `BuildConfig`s using Custom strategy. The builder container in this repository requires the under development changes [here].

# CNB Container Image

The container image is at `ghcr.io/otaviof/os-custom-paketo-builder`, you can either import a pre-build image to a local `ImageStreams` or build it yourself.

```bash
docker pull ghcr.io/otaviof/os-custom-paketo-builder:latest
```

## Importing to ImageStreams

When working with the pre-existing container image, just import it into the local ImageStreams, i.e.:

```bash
oc import-image $(basename ${PWD}) \
	--from="ghcr.io/otaviof/os-custom-paketo-builder:latest" \
	--confirm
```

## OpenShift Build

When working on this repository, you can first create a `binary` build for the local repository name:

```bash
oc new-build \
	--strategy=docker \
	--binary \
	--to="$(basename ${PWD}):latest" \
	--name="$(basename ${PWD})"
```

Then, rinse and repeat your changes building a new container image with the local directory. For instance:

```bash
oc start-build $(basename ${PWD}) --from-dir="." --follow --wait
```

# Example `BuildConfig`

A detailed `BuildConfig` example is found on the [`os` directory](./os/README.md), please consider.

[otaviofOCM]: https://github.com/otaviof/openshift-controller-manager/tree/BUILD-558