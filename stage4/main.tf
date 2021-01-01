resource "helm_release" "example" {
  name       = "my-redis-release"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "6.0.1"

  values = [
    "${file("values.yaml")}"
  ]

  set {
    name  = "cluster.enabled"
    value = "true"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "service.annotations.prometheus\\.io/port"
    value = "9127"
    type  = "string"
  }
}

# data "template_file" "yaml_template" {
#   template = "${file("azure_identity.yaml")}"
# }
# 
# resource "null_resource" "yaml_deployment" {
#   triggers = {
#     manifest_sha1 = "${sha1("${data.template_file.yaml_template.rendered}")}"
#   }
# 
#   provisioner "local-exec" {
#     command = "kubectl apply -f -<<EOF\n${data.template_file.yaml_template.rendered}\nEOF"
#   }
# }