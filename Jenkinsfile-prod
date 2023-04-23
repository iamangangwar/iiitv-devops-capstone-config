pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub')
    }
    stages {
        stage('Fetch Code') {
            steps {
                git branch: 'master', url: 'https://github.com/iamangangwar/iiitv-devops-capstone.git'
            }
        }

        stage('Test Dockerfile') {
            steps {
                sh "docker build -t iamangangwar/iiitv-devops-capstone-prod:${BUILD_NUMBER} ."
            }
        }

        stage('Build Image') {
            steps {
                script {
                    sh "docker build -t iamangangwar/iiitv-devops-capstone-prod:${BUILD_NUMBER} ."
                    sh "docker build -t iamangangwar/iiitv-devops-capstone-prod:latest ."
                }
            }
        }
        
        stage('Upload Image') {
            steps {
                script {
                    sh "docker login -u ${DOCKERHUB_CREDENTIALS_USR} -p ${DOCKERHUB_CREDENTIALS_PSW}"
                    sh "docker push iamangangwar/iiitv-devops-capstone-prod:${BUILD_NUMBER}"
                    sh "docker push iamangangwar/iiitv-devops-capstone-prod:latest"
                }
            }
        }
        
        stage('Deploy on Production Server') {
            steps {
                script {
                    try {
                        sh "docker service create \
                            --name site \
                            --publish published=80,target=80 \
                            --replicas 3 \
                            iamangangwar/iiitv-devops-capstone-prod:latest"
                    }
                    catch(e) {
                        sh "docker service update \
                            --image iamangangwar/iiitv-devops-capstone-prod:latest \
                            site"
                    }
                }
            }
        }
    }
    post {
        always {
            sh "docker logout"
        }
    }
}