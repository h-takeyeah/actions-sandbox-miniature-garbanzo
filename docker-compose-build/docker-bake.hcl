target "docker-metadata-action" {}

group "default" {
  targets = ["hello-world"]
}

target "hello-world" {
  inherits = ["docker-metadata-action"]
}

