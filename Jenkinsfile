#!groovy

/**
 * This pipeline describes a CI/CD process for running Golang app to multi stages environment
 */

def podLabel = "jenkins-worker-${UUID.randomUUID().toString()}"
def host = "173-193-102-57.nip.io"
def dockerImage = 'sergeyglad/wiki'


podTemplate(label: podLabel, yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: golang
    image: golang:1.13.0-alpine
    command:
      - "cat"
    tty: true
  - name: docker-dind
    image: docker:stable-dind
    securityContext:
      privileged: true
  - name: kubectl
    image: lachlanevenson/k8s-kubectl
    tty: true
    command:
      - "cat" 
  - name: helm
    image: lachlanevenson/k8s-helm:v2.16.1
    tty: true
    command:
      - "cat"
"""){
	node(podLabel) {

		stage('Checkout application SCM') {
			checkout scm
		}

		stage('Build  Golang app') {
			container('golang') {
				echo "Build Golang app"
				sh 'CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags="-w -s" -o main .'
			}
		}

		stage ('Unit test Golang app')  {
			container('golang') {
				echo "Unit test Golang app"
				sh 'CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go test -v .'
			}
		}

	    stage('Docker build') {
			container('docker-dind') {
				sh "docker build . -t $dockerImage"
			}
		}

		stage ('Docker push') {
			container('docker-dind') {
				sh 'docker image ls'
				withDockerRegistry([credentialsId: 'docker-api-key', url: 'https://index.docker.io/v1/']) {
					sh "docker push $dockerImage"
				}
		  }
		}

		stage ('Service delivery') {
			container('kubectl') {
				withKubeConfig([credentialsId: 'kubeconfig', serverUrl: 'https://34.67.92.12']) {
    				 sh '''
					   
					   kubectl run wiki --image=sergeyglad/wiki --replicas=3 --port=3000 --labels=app=simple --namespace=default

					'''  
    		}
		  }
		}
	}// node
} //podTemplate

