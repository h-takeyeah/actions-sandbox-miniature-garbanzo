target "docker-metadata-action" {}

target "hello-world" {
  inherits = ["docker-metadata-action"]
}

