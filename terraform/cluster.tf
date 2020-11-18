
resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  initial_node_count = 3

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

  }
}


resource "null_resource" "kubectl_ver_checking" {
  provisioner "local-exec" {
    command = "bash kubectl_version.sh && bash helm_version.sh"
    on_failure = fail
  }
  depends_on = [google_container_cluster.primary]
}

resource "null_resource" "configure_tiller" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<LOCAL_EXEC
      gcloud container clusters get-credentials  sun-cluster --region us-central1-a
      
      kubectl apply -f create-helm-service-account.yml
      helm init --service-account tiller --wait
      kubectl rollout status -w deployment/tiller-deploy --namespace=kube-system
    LOCAL_EXEC
   }
 depends_on = [null_resource.kubectl_ver_checking]

}

resource "null_resource" "configure_jenkins" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<LOCAL_EXEC
      kubectl apply -f pv_jenkins.yaml
      helm install jenkins -n jenkins  jenkinsci/jenkins
    LOCAL_EXEC
   }
  
}
