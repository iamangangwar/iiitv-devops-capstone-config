pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub')
    }
    stages {
        stage('Fetch Code') {
            steps {
                git branch: 'develop', url: 'https://github.com/iamangangwar/iiitv-devops-capstone.git'
            }
        }

        stage('Test Dockerfile') {
            steps {
                sh "docker build -t iiitv-devops-capstone-test:${BUILD_NUMBER} ."
            }
        }

        stage('Build Image') {
            steps {
                sh "docker build -t iamangangwar/iiitv-devops-capstone-test:${BUILD_NUMBER}"
            }
        }
        
        stage('Upload Image') {
            steps {
                script {
                    sh "docker login -u ${DOCKERHUB_CREDENTIALS_USR} -p ${DOCKERHUB_CREDENTIALS_PSW}"
                    sh "docker push iamangangwar/iiitv-devops-capstone-test:${BUILD_NUMBER}"
                    sh "docker push iamangangwar/iiitv-devops-capstone-test:latest"
                }
            }
        }
        
        stage('Deploy on Test Server') {
            stages {
                stage('SCM Checkout') {
                    steps {
                        git 'https://github.com/iamangangwar/iiitv-devops-capstone-config.git'
                    }
                }
                stage('Run Ansible Playbook') {
                    steps {
                        ansiblePlaybook credentialsId: 'ansible-master', disableHostKeyChecking: true, installation: 'ansible', inventory: 'hosts', playbook: 'test-deploy.yml'
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