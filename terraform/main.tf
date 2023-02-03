locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "vpc-09b96c51e3fabd9cd"
  ssh_user = "ubuntu"
  key_name = "mickltokey"
  private_key_path = "/Users/toshmickler/projects/capstone/terraform/mickltokey.pem"
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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

   #Calico networking (BGP)
   ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

   ingress {
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  ingress {
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

   ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

   ingress {
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }   

   ingress {
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }      

   #Calico networking with VXLAN enabled
   #flannel networking (VXLAN)
   ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
   #Calico networking with Typha enabled
   ingress {
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
   #Calico networking with IPv4 Wireguard enabled
   ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  #Calico networking with IPv6 Wireguard enabled
  ingress {
    from_port   = 51821
    to_port     = 51821
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  


   #etcd datastore
   ingress {
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  # Allow all internal
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
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
/* 
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${local_file.hosts_cfg.filename} --user ${local.ssh_user} --private-key ${local.private_key_path} ../ansible/playbook.yaml -vvv"
  } */
}

