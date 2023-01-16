locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "vpc-06fa01b45bf396242"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/Users/toshmickler/projects/capstone/terraform/Demokey.pem"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "ASIA3NGD24IXA5QKBMYM"
  secret_key = "IpqoBS2C6jWMuI8s46wLrI24MhUmLpM6M2WhFBjq"
  token = "FwoGZXIvYXdzEMn//////////wEaDFtdICB/Bzd7LbLcMSKzAeUO6OyxiyJRSwfd2US84x7DKcWhqC6ct8W0rDXip0i/EApCTRc6gnxXfz3+3ud2xSb8w4BnO9x3kv6DfByC60BsIubEGTT1saldIUfrDleYp2RtweYc/vQI1ak8Ohgb3uE9EyDjtgXJbq+3jtOw0/9iyIvdQzQqVZieoM/VQx69EX7dm24OBtoHzSSDgsRQrpYRFnxElajzxyEDtVGBEhM+uZzH2AGk7hHMa5/3d6EUjSCCKOCOkp4GMi1f2w56XwtKSt0f4pCdRbLk95xOvqP2iA6+2kOtimjfCDVeUtAhNBzEoB1kwJo="
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

resource "aws_instance" "kubernetes-main" {
  for_each = toset(["control"])
  
  ami = local.ami_id
  instance_type = "t3.micro"
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

}

resource "aws_instance" "kubernetes-worker" {
  for_each = toset(["worker1", "worker2"])
  
  ami = local.ami_id
  instance_type = "t3.micro"
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
  
/*   provisioner "local-exec" {
    command = "echo ${self.public_ip} >> myhosts" 
  } */
  

}
# generate inventory file for Ansible
resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/hosts.tpl",
    {
      control_nodes = values(aws_instance.kubernetes-main)[*].public_ip
      worker_nodes = values(aws_instance.kubernetes-worker)[*].public_ip
    }
  )
  filename = "../ansible/inventory/hosts.cfg"

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${local_file.hosts_cfg.filename} --user ${local.ssh_user} --private-key ${local.private_key_path} ../ansible/master-playbook.yaml"
  } 
}

