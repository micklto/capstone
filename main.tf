locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "<YOUR_VPC_ID>"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/home/labsuser/assign/Demokey.pem"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "<YOUR_ACCESS_KEY>"
  secret_key = "<YOUR_SECRET_KEY>"
  token = "<YOUR_SECURITY_TOKEN>"
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

resource "aws_instance" "control" {
  ami = local.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  vpc_security_group_ids =[aws_security_group.demoaccess.id]
  key_name = local.key_name

  tags = {
    Name = "K8s Control Node"
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
  
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > myhosts" 
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} playbook.yml" 
  }

}

resource "aws_instance" "worker1" {
  ami = local.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  vpc_security_group_ids =[aws_security_group.demoaccess.id]
  key_name = local.key_name

  tags = {
    Name = "K8s Control Node"
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
  
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > myhosts" 
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} playbook.yml" 
  }

}

output "instance_ip" {
  value = aws_instance.worker1.public_ip
}



