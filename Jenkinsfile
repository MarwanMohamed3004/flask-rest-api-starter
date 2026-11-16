
pipeline {
    agent {
        label 'ubuntu-client'
    }

    options {
        skipDefaultCheckout(true)
    }

    environment {
        IMAGE_REPO = 'marwan304/flask-rest-api-starter'
    }

    stages {

        // 1. Checkout source code
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code downloaded successfully!'
            }
        }

        // 2. Verify Docker
        stage('Check Docker') {
            steps {
                sh '''
                    docker --version
                    docker info
                '''
            }
        }

        // 3. Install Python dependencies
        stage('Install Dependencies') {
            steps {
                sh '''
                    python3 -m venv .venv
                    .venv/bin/pip install -r requirements.txt
                '''
            }
        }

        // 4. Run application tests
        stage('Run Tests') {
            steps {
                sh '''
                    .venv/bin/python test_app.py
                '''
            }
        }

        // 5. Build Docker image
        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e

                    echo "Building Docker image..."

                    docker build --pull \
                        -t "$IMAGE_REPO:$BUILD_NUMBER" \
                        -t "$IMAGE_REPO:latest" .

                    echo "Docker image built successfully!"

                    docker images "$IMAGE_REPO"
                '''
            }
        }

        // 6. Security Scan using Trivy
        stage('Security Scan') {
            steps {
                sh '''
                    echo "Starting Docker image security scan..."

                    trivy image \
                        --scanners vuln \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --exit-code 0 \
                        "$IMAGE_REPO:$BUILD_NUMBER"

                    echo "Security scan completed!"
                '''
            }
        }

        // 7. Push Docker image to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set -eu
                        set +x

                        trap 'docker logout >/dev/null 2>&1 || true' EXIT

                        echo "$DOCKERHUB_TOKEN" | docker login \
                            --username "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        echo "Pushing versioned image..."
                        docker push "$IMAGE_REPO:$BUILD_NUMBER"

                        echo "Pushing latest image..."
                        docker push "$IMAGE_REPO:latest"

                        echo "Images successfully pushed to Docker Hub!"
                    '''
                }
            }
        }

        // 8. Deploy Docker container
        stage('Deploy Docker Container') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set -eu
                        set +x

                        trap 'docker logout >/dev/null 2>&1 || true' EXIT

                        echo "$DOCKERHUB_TOKEN" | docker login \
                            --username "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        echo "Pulling image from Docker Hub..."
                        docker pull "$IMAGE_REPO:$BUILD_NUMBER"
                    '''
                }

                sh '''
                    set -e

                    echo "Removing previous container if it exists..."
                    docker rm -f flask-api || true

                    echo "Starting new container..."

                    docker run -d \
                        --name flask-api \
                        --restart unless-stopped \
                        -p 5001:8080 \
                        "$IMAGE_REPO:$BUILD_NUMBER"

                    echo "Container deployed successfully!"

                    docker ps
                '''
            }
        }

        // 9. Verify deployed API
        stage('Verify API') {
            steps {
                sh '''
                    python3 - <<'PY'
import json
import time
import urllib.request

url = "http://127.0.0.1:5001/items"

for attempt in range(1, 31):
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())

            print("HTTP Status:", response.status)
            print("API Response:", data)

            assert response.status == 200
            assert isinstance(data, list)

            print("API verification successful!")
            break

    except Exception as error:
        if attempt == 30:
            raise

        print(f"Waiting for application... Attempt {attempt}")
        time.sleep(2)
PY
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD Pipeline completed successfully!'
            echo 'Docker image built, security scanned, pushed and deployed!'
        }

        failure {
            echo 'Pipeline failed! Check the stage logs.'
        }
    }
}
