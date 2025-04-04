# docker-compose-build

This directory contains the contents that are used to build container image using docker-bake.hcl.
Previously I used compose.yaml so the name of this directory comes from there.

You can utilize the workflow file `build-push-docker-image.yml`

## Annotations

Though this bake file is not designed to be used to build multi arch image, it produces an additional image for the platform of `unknown/unknown` which is explained later section.
So as a result, GitHub Package page shows this hello-world image is multi arch one([example](https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo/pkgs/container/hello-world/388459635?tag=0.0.4-1)).

According to the documentation, to add annotations in order to display information about this image on the GitHub Pakage page,
annotaions must be appear in **index** level.

That's why the workflow has `DOCKER_METADATA_ANNOTATIONS_LEVELS` environment variable.

## Customization

Final goal of this directory and the corresponding workflow is pushing image to a container registry.
The workflow pushed the image to GitHub Container Registry(ghcr.io).

### Prefer single archtecture image (e.g. erace `unknown/unknown`)

Running the workflow, you will get multi arch image even the bake file include only one platform to be built.
It is because the additional manifest is consumed to create provenance [Attestations](https://docs.docker.com/build/metadata/attestations/).
Literally speaking attestations manifest would represent a platform but `unknown/unknown` is just a placeholder to avoid users from using this by accident.
If you prefer get rid of this, you can modify the bake file like this.

```hcl
target "hello-world" {
  attest = [
    {
      type = "provenance"
      disabled = true # (vice versa)
    }
  ]
}
```

Or set `provenance` `false` at the input of [docker/bake-action](https://github.com/docker/bake-action/blob/v6.5.0/README.md#customizing).
Setting `provenance` `false` may change metadata format which is generated from [those of OCI](https://github.com/opencontainers/image-spec/blob/v1.1.1/spec.md) to Docker's one[(Image Manifest V2)](https://distribution.github.io/distribution/spec/manifest-v2-2/).
If you wanna restore the manifest to OCI, then adding `--set=*.output=type=image,oci-mediatypes=true` to the builder command is a solution.

Editing workflow is easy way to do this:

```yml
jobs:
  build-and-push:
    steps:
      - name: Docker Buildx Bake
        uses: docker/bake-action@v6
          with:
            provenance: false
            set: |
              *.cache-from=type=gha,scope=image
              *.cache-to=type=gha,scope=image
              *.output=type=image,push=true,oci-mediatypes=true # add
```

See also:
- https://github.com/orgs/community/discussions/45969
- https://github.com/docker/buildx/issues/1533

## How to utilize on local machine

First of all, if there are no builder whose type is "docker-container", then create new one.
```
docker builder ls # Is there at least 1 builder whose driver is "docker-cotainer"?
docker buildx create --name container --driver docker-container --bootstrap
```

**ex1** To get metadata manifests

```bash
docker buildx bake --file docker-bake.hcl --builder container --set='*.output=type=oci,dest=/tmp/hello-world-output.tar'
tar xf /tmp/hello-world-output.tar
```

**ex2** To test labels are properly merged

Touch json files which simulate the output of docker/metadata-action.

Save this as docker-metadata-action-bakefile-annotations.json

```json
{
  "target": {
    "docker-metadata-action": {
      "annotations": [
        "index:org.opencontainers.image.created=2025-04-04T03:46:40.367Z",
        "index:org.opencontainers.image.description=Containernized helloworld written in Go",
        "index:org.opencontainers.image.licenses=MIT",
        "index:org.opencontainers.image.revision=b2b37957cc44b619f16de24307cf5f79942b4278",
        "index:org.opencontainers.image.source=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "index:org.opencontainers.image.title=actions-sandbox-miniature-garbanzo",
        "index:org.opencontainers.image.url=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "index:org.opencontainers.image.version=0.0.4-1",
        "manifest:org.opencontainers.image.created=2025-04-04T03:46:40.367Z",
        "manifest:org.opencontainers.image.description=Containernized helloworld written in Go",
        "manifest:org.opencontainers.image.licenses=MIT",
        "manifest:org.opencontainers.image.revision=b2b37957cc44b619f16de24307cf5f79942b4278",
        "manifest:org.opencontainers.image.source=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "manifest:org.opencontainers.image.title=actions-sandbox-miniature-garbanzo",
        "manifest:org.opencontainers.image.url=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "manifest:org.opencontainers.image.version=0.0.4-1"
      ]
    }
  }
}
```

Save this as docker-metadata-action-bakefile.json

```json
{
  "target": {
    "docker-metadata-action": {
      "labels": {
        "org.opencontainers.image.created": "2025-04-04T03:46:40.367Z",
        "org.opencontainers.image.description": "Containernized helloworld written in Go",
        "org.opencontainers.image.licenses": "MIT",
        "org.opencontainers.image.revision": "b2b37957cc44b619f16de24307cf5f79942b4278",
        "org.opencontainers.image.source": "https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "org.opencontainers.image.title": "actions-sandbox-miniature-garbanzo",
        "org.opencontainers.image.url": "https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "org.opencontainers.image.version": "0.0.4-1"
      },
      "tags": [
        "0.0.4-1",
        "sha-b2b3795"
      ],
      "args": {
        "DOCKER_META_IMAGES": "",
        "DOCKER_META_VERSION": "0.0.4-1"
      }
    }
  }
}
```

And then

```bash
$ buildx bake --builder=container --print \
--file docker-bake.hcl \
--file docker-metadata-action-bakefile-annotations.json \
--file docker-metadata-action-bakefile.json
[+] Building 0.0s (1/1) FINISHED
 => [internal] load local bake definitions                                                                                                                                                                                             0.0s
 => => reading docker-bake.hcl 315B / 315B                                                                                                                                                                                             0.0s
 => => reading docker-metadata-action-bakefile-annotations.json 1.48kB / 1.48kB                                                                                                                                                        0.0s
 => => reading docker-metadata-action-bakefile.json 909B / 909B                                                                                                                                                                        0.0s
{
  "group": {
    "default": {
      "targets": [
        "hello-world"
      ]
    }
  },
  "target": {
    "hello-world": {
      "annotations": [
        "index:org.opencontainers.image.created=2025-04-04T03:46:40.367Z",
        "index:org.opencontainers.image.description=Containernized helloworld written in Go",
        "index:org.opencontainers.image.licenses=MIT",
        "index:org.opencontainers.image.revision=b2b37957cc44b619f16de24307cf5f79942b4278",
        "index:org.opencontainers.image.source=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "index:org.opencontainers.image.title=actions-sandbox-miniature-garbanzo",
        "index:org.opencontainers.image.url=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "index:org.opencontainers.image.version=0.0.4-1",
        "manifest:org.opencontainers.image.created=2025-04-04T03:46:40.367Z",
        "manifest:org.opencontainers.image.description=Containernized helloworld written in Go",
        "manifest:org.opencontainers.image.licenses=MIT",
        "manifest:org.opencontainers.image.revision=b2b37957cc44b619f16de24307cf5f79942b4278",
        "manifest:org.opencontainers.image.source=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "manifest:org.opencontainers.image.title=actions-sandbox-miniature-garbanzo",
        "manifest:org.opencontainers.image.url=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "manifest:org.opencontainers.image.version=0.0.4-1"
      ],
      "context": ".",
      "dockerfile": "Dockerfile",
      "args": {
        "DOCKER_META_IMAGES": "",
        "DOCKER_META_VERSION": "0.0.4-1"
      },
      "labels": {
        "org.opencontainers.image.created": "2025-04-04T03:46:40.367Z",
        "org.opencontainers.image.description": "Containernized helloworld written in Go",
        "org.opencontainers.image.licenses": "MIT",
        "org.opencontainers.image.revision": "b2b37957cc44b619f16de24307cf5f79942b4278",
        "org.opencontainers.image.source": "https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "org.opencontainers.image.title": "actions-sandbox-miniature-garbanzo",
        "org.opencontainers.image.url": "https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo",
        "org.opencontainers.image.version": "0.0.4-1"
      },
      "tags": [
        "ghcr.io/h-takeyeah/hello-world:0.0.4-1",
        "ghcr.io/h-takeyeah/hello-world:sha-b2b3795"
      ]
    }
  }
}
```
