locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "vpc-0d74804362f22cf70"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/Users/toshmickler/projects/capstone/terraform/Demokey.pem"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "ASIA3NGD24IXNPNE55GJ"
  secret_key = "4t9AFpYjpd2PzepVCgvbfu5/+bEKPH477o/TahCZ"
  token = "FwoGZXIvYXdzENP//////////wEaDBFlwFDuR81fogAtJyKzAd6Be3+zTRAW8wPjEITySStl0ZSxpS/2XBfwunbndVfKJJdteRPADigTWEgDvRu9Mol+4AwrXu7IZScRTbPrN1gA9EI0F89ZPLWo1U/cm7sVL6rymT7EaERIXp761PRBRNsFZ21xmeh6FcFEGYYWZkUh+kZdRj7RletlF+xV/isdWCTQc5k2iiiD5JsSzlVqRbEtyLzkZR26a6JLwczKtqzg2NgLkNSP8/HUCgFl1SzYj8l9KLTIzJ4GMi3IAFyNylaJ+ULq00Q5smdFpPhZziyEPqLOaaVpg9TKP3WWesoVt0unaXILmI4="
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
  ingress {
		from_port   = 6443
		to_port     = 6443
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

data "aws_vpc" "selected" {
  id = local.vpc_id
}

# TODO - Need to wait until infrastructure is created before proceeding to run ansible
# generate variable file for Ansible
resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/ansiblevars.tpl",
    {
      master_node = values(aws_instance.kubernetes-main)[0].private_ip
      #pod_network_cidr = cidrsubnet(data.aws_vpc.selected.cidr_block, 4, 1)
      pod_network_cidr = data.aws_vpc.selected.cidr_block
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
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${local_file.hosts_cfg.filename} --user ${local.ssh_user} --private-key ${local.private_key_path} ../ansible/master-playbook.yaml -vvv"
  }
}

