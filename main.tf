provider "aws" {
    region = "us-east-1"
    access_key = "<access-key>"
    secret_key = "<access-key>"
}

# Defining external data source to get the IP address of the machine running Terraform
data "external" "myipaddr" {
  program = ["bash", "-c", "curl -s 'https://ipinfo.io/json'"]
}

resource "aws_key_pair" "capstone-key" {
  key_name   = "capstone-key"
  public_key = "<public-key>"
}


# Creating security group for Jenkins Server
# SG allows SSH from my IP
# SG allows port 8080 from anywhere
resource "aws_security_group" "jenkins-capstone-sg" {
    name = "jenkins-capstone-sg"
    description = "Security Group for Jenkins Server for Capstone Project"

    ingress {
        description = "Allow SSH from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "${data.external.myipaddr.result.ip}/32" ]
    }

    ingress {
        description = "Allow port 8080 from anywhere"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "jenkins-capstone-sg"
        Project = "Capstone"
    }
}

# Creating security group for Test Server
# SG allows SSH from my IP
# SG allows port 80 from anywhere
# SG allows all traffic from Jenkins Server
resource "aws_security_group" "test-capstone-sg" {
    name = "test-capstone-sg"
    description = "Security Group for Test Server for Capstone Project"

    ingress {
        description = "Allow SSH from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "${data.external.myipaddr.result.ip}/32" ]
    }

    ingress {
        description = "Allow port 80 from anywhere"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow all traffic from Jenkins Server"
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = [aws_security_group.jenkins-capstone-sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "test-capstone-sg"
        Project = "Capstone"
    }
}

# Creating security group for Production Server
# SG allows SSH from my IP
# SG allows port 80 from anywhere
# SG allows all traffic from Jenkins Server
resource "aws_security_group" "prod-capstone-sg" {
    name = "prod-capstone-sg"
    description = "Security Group for Production Server for Capstone Project"

    ingress {
        description = "Allow SSH from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "${data.external.myipaddr.result.ip}/32" ]
    }

    ingress {
        description = "Allow port 80 from anywhere"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow all traffic from Jenkins Server"
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = [aws_security_group.jenkins-capstone-sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "prod-capstone-sg"
        Project = "Capstone"
    }
}

# Creating Jenkins Server
# Properties -
#   - Instance type: t2.medium
#   - AMI: Ubuntu 20.04 (LTS)
#   - Security Group: jenkins-capstone-sg
#   - Key Pair: capstone-key
resource "aws_instance" "jenkins-capstone" {
    ami = "ami-0aa2b7722dc1b5612"
    instance_type = "t2.medium"
    key_name = "capstone-key"
    security_groups = [aws_security_group.jenkins-capstone-sg.name]
    user_data = <<-EOF
    #!/bin/bash

    # Install Jenkins
    sudo apt update
    sudo apt install git openjdk-11-jdk -y
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt update
    sudo apt-get update
    sudo apt-get install jenkins -y

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Install Ansible
    sudo apt update
    sudo apt install software-properties-common -y
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt-get install ansible -y
    EOF

    tags = {
        Name = "jenkins-capstone"
        Project = "Capstone"
    }
}

# Creating Test Server
# Properties -
#   - Instance type: t2.micro
#   - AMI: Ubuntu 20.04 (LTS)
#   - Security Group: test-capstone-sg
#   - Key Pair: capstone-key
resource "aws_instance" "test-capstone" {
    ami = "ami-0aa2b7722dc1b5612"
    instance_type = "t2.micro"
    key_name = "capstone-key"
    security_groups = [aws_security_group.test-capstone-sg.name]
    user_data = <<-EOF
    #!/bin/bash

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg
    sudo apt install git python3 python3-pip -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    EOF

    tags = {
        Name = "test-capstone"
        Project = "Capstone"
    }
}

# Creating Production Server
# Properties -
#   - Instance type: t2.micro
#   - AMI: Ubuntu 20.04 (LTS)
#   - Security Group: prod-capstone-sg
#   - Key Pair: capstone-key
resource "aws_instance" "prod-capstone" {
    ami = "ami-0aa2b7722dc1b5612"
    instance_type = "t2.micro"
    key_name = "capstone-key"
    security_groups = [aws_security_group.prod-capstone-sg.name]
    user_data = <<-EOF
    #!/bin/bash

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg
    sudo apt install git python3 python3-pip -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # # Install Minikube
    # curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
    # sudo dpkg -i minikube_latest_amd64.deb

    # # Install Kubernetes
    # sudo apt-get update
    # sudo apt-get install -y ca-certificates curl
    # sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    # echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    # sudo apt-get update
    # sudo apt-get install -y kubectl
    EOF

    tags = {
        Name = "prod-capstone"
        Project = "Capstone"
    }
}