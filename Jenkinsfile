
pipeline {
    agent {
        label 'ubuntu-client'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code downloaded on Ubuntu Client!'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    python3 -m venv .venv
                    .venv/bin/pip install -r requirements.txt
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    .venv/bin/python test_app.py
                '''
            }
        }

        stage('Deploy to Ubuntu Client') {
            steps {
                sh '''
                    set -e

                    APP_DIR="/home/marwan/flask-app"

                    echo "Copying application files..."
                    mkdir -p "$APP_DIR"
                    cp app.py requirements.txt "$APP_DIR/"

                    echo "Installing production dependencies..."
                    cd "$APP_DIR"
                    python3 -m venv .venv
                    .venv/bin/pip install -r requirements.txt

                    echo "Restarting Flask application..."
                    sudo -n /usr/bin/systemctl restart flask-app

                    echo "Checking application status..."
                    sudo -n /usr/bin/systemctl is-active flask-app
                '''
            }
        }

        stage('Verify API') {
            steps {
                sh '''
                    python3 - <<'PY'
import json
import urllib.request

url = "http://127.0.0.1:5000/items"

with urllib.request.urlopen(url, timeout=10) as response:
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
