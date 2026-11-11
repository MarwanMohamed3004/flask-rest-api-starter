
pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    environment {
        DEPLOY_HOST = '192.168.56.102'
        DEPLOY_USER = 'marwan'
        DEPLOY_DIR = '/home/marwan/flask-app'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code downloaded!'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    . .venv/bin/activate
                    python test_app.py
                '''
            }
        }

        stage('Deploy to Ubuntu Client') {
            steps {
                sshagent(credentials: ['client-deploy-key']) {

                    sh '''
                        set -e

                        echo "Creating application directory..."

                        ssh -o StrictHostKeyChecking=no \
                            $DEPLOY_USER@$DEPLOY_HOST \
                            "mkdir -p $DEPLOY_DIR"

                        echo "Copying application files..."

                        scp -o StrictHostKeyChecking=no \
                            app.py requirements.txt \
                            $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_DIR/

                        echo "Installing application dependencies..."

                        ssh -o StrictHostKeyChecking=no \
                            $DEPLOY_USER@$DEPLOY_HOST \
                            "cd $DEPLOY_DIR && \
                            python3 -m venv .venv && \
                            .venv/bin/pip install -r requirements.txt"

                        echo "Restarting Flask application..."

                        ssh -o StrictHostKeyChecking=no \
                            $DEPLOY_USER@$DEPLOY_HOST \
                            "sudo -n /usr/bin/systemctl restart flask-app"

                        echo "Checking application status..."

                        ssh -o StrictHostKeyChecking=no \
                            $DEPLOY_USER@$DEPLOY_HOST \
                            "sudo -n /usr/bin/systemctl is-active flask-app"
                    '''
                }
            }
        }

        stage('Verify API') {
            steps {
                sh '''
                    python3 - <<'PY'
import json
import urllib.request

url = 'http://192.168.56.102:5000/items'

response = urllib.request.urlopen(url, timeout=10)

data = json.loads(response.read().decode())

print("HTTP Status:", response.status)
print("API Response:", data)

assert response.status == 200
assert isinstance(data, list)

print("API verification successful!")
PY
                '''
            }
        }
    }

    post {
        success {
            echo 'Deployment completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the console output.'
        }
    }
}
