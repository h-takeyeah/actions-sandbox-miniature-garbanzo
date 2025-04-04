target "docker-metadata-action" {}

group "default" {
  targets = ["hello-world"]
}

target "hello-world" {
  description = "Build"
  inherits = ["docker-metadata-action"]
  # thanks! https://github.com/docker/metadata-action/issues/398
  tags = [for tag in target.docker-metadata-action.tags : "ghcr.io/h-takeyeah/hello-world:${tag}"]
}

