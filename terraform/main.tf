locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "vpc-0b472ec5e11139336"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/Users/toshmickler/projects/capstone/terraform/Demokey.pem"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "ASIA3NGD24IXJR3CFFAX"
  secret_key = "WFm8AE4ee29DdUzcWqyDzREPBkQSkdGYTmlVMDHI"
  token = "FwoGZXIvYXdzEFYaDEUsh1dQbIP5DnBWWCKzAfb/lyFzZRhwyEISUMOIfzKwr6aiG5WiXYGi9jaY5dIW2CWNcEipURFxFwCWRnakAfPgMb5PtmNO+V9ZGx9EbGZNzs42Zbj9DgoMufGiLb5a4wAfkiuGx1nUQTcG3fB8Y0HwNOHhniKTkkKzkw9qvcpf3dTMYLWr6uPMnpNUmKKRgHPt2r31na+Nr75Go81rEJ133twKqTm6GvisvizDNFZsywFbeJY3VkhDcsJqqi9qiw+lKJuNsZ4GMi2HGxbsU9+Opk1luAJgB/IpAQ5pMG13EgWAs0igweH22jjXFH3W8Kf58C0TC3g="
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

}

# TODO - Need to wait until infrastructure is created before proceeding to run ansible
# generate variable file for Ansible
resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/ansiblevars.tpl",
    {
      master_node = values(aws_instance.kubernetes-main)[0].private_ip
    }
  )
  filename = "../ansible/vars/default.yaml"
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

