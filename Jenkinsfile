pipeline {

    // Defines where this pipeline should run (e.g., an ubuntu worker node)
    agent any

    // Define variables we will use throughout the pipeline 
    environment {
        // We dynamically tag our image using the unique git commit hash!
        IMAGE_TAG = "${env.GIT_COMMIT}"
        IMAGE_NAME = "my-registry.io/devops-web-app"
    }


    stages {
        stage('Step 1: Check Out Code') {
            steps {
                // Jenkins automatically runs 'git clone' and 'git checkout'
                // based on the branch that triggered the webhook.
                checkout scm
                echo "Successfully pulled commit: ${IMAGE_TAG}"
            }

        }

        stage('Step 2: Build Docker Image') {
            steps {
                // We use the Dockerfile you created earlier
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
                echo "Image built successfully!"
            }

        }

        stage('Step 3: Push to Container Registry') {
            steps {
                // in a real pipeline, we securely inject credentials here 
                withCredentials([usernamePassword(credentialsId: 'docker-registry-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin my-registry.io'
                    sh 'docker push ${IMAGE_NAME}:${IMAGE_TAG}'
                }

            }
 
        }

        stage('Step 4: Deploy to kubernetes') {
            // We only want to deploy to production if this is the main branch 
            when {
                branch 'main'
            }
            steps {
                // We inject our Kubernetes configuration to allow access to the cluster
                withKubeConfig(credentialsId: 'k8s-cluster-config') {
                    // Update the deployment with the exact Git commit image tag
                    sh 'kubectl set image deployment/web-app web-ap=${IMAGE_NAME}:${IMAGE_TAG}'
                    sh 'kubectl rollout status deployment/web-app'
                }

            }

        }

    }

    // This block runs no matter what happens above 
    post {
        success {
            echo "  Pipeline completed successfully! Code is Live."
            // Here you might send a Slack notification
        }
        failure {
            echo " Pipeline failed. Check the logs."
        }

    }

}


































