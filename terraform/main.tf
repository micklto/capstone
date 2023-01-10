locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "vpc-05b1b209ad6a4ce79"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/Users/toshmickler/projects/capstone/terraform/Demokey.pem"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "ASIA3NGD24IXOJDELDIM"
  secret_key = "vY6myqA03GQOzVHESoohqFgoUvNOO8gBztj4XcL/"
  token = "FwoGZXIvYXdzEDwaDHSfjiyPckCgIByQ/CKzAStHDPNCY197ebs94R4z6p8EabBX45VAT+GUxXh89pB3DQSmGyn/C12AkxxSdzinIPdml6A8XCahz4M7icIuu9zfVO2VQjClOjZ5JKCPJcG3AMghTDQB9eZUZDj6m1hKTsXBb6CiWM2YDMxrgdO+ig1HH8i7Tgx0b9c9kayYAs4g+5dL+wJGXHWV+6ePFRTYQisORHcrUrpgWcoScQeaqfVTM64Ka5TcaM/K1DNuWa+LuNoFKOeU850GMi3czjyrLBLcHLlNJ6fqFgQGoses45MNclp1Tkw8OsExRPLGNRDIJ7J8aHjhKfo="
}

resource "aws_security_group" "demoaccess" {
	name   = "demoaccess"
	vpc_id = local.vpc_id

  ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
  ingress {
		from_port   = 80
		to_port     = 80
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
  egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "kubernetes" {
  for_each = toset(["control", "worker1", "worker2"])

  #host_id = "${each.key}"
  
  ami = local.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  vpc_security_group_ids =[aws_security_group.demoaccess.id]
  key_name = local.key_name

  tags = {
    Name = "${each.key}"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  }

  provisioner "remote-exec" {
    inline = [
      "hostname"
    ]
  }

  # Remotely execute commands to install Java, Python, Jenkins
  /* provisioner "remote-exec" {
    inline = [
      "sudo apt update && upgrade",
      "sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt update",
      "sudo apt -y install docker-ce docker-ce-cli containerd.io",
      "sudo usermod -aG docker $USER",
      "newgrp docker",
      "docker -version"
     
    ]
  } */
  
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> myhosts" 
  }

  #provisioner "local-exec" {
  #  command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} playbook.yml" 
  #}

}
# generate inventory file for Ansible
resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/hosts.tpl",
    {
      control_nodes = values(aws_instance.kubernetes)[*].public_ip
      worker_nodes = values(aws_instance.kubernetes)[*].public_ip
    }
  )
  filename = "../ansible/inventory/hosts.cfg"

  depends_on = [
    aws_instance.kubernetes
  ]
}
