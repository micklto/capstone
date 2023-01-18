locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "vpc-084388df05c673a3e"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/Users/toshmickler/projects/capstone/terraform/Demokey.pem"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "ASIA3NGD24IXCMQT2S77"
  secret_key = "QBV/qWp/CnjHvl5a0qMNwMQNhKzSdJlGU1icvkx2"
  token = "FwoGZXIvYXdzEOL//////////wEaDBQiPRy7NEMsRKHnoSKzAa72mK8lSqMoOKdDMHoYW4oDw0JwFESODuyGWWkWzZQUEf4PNb0W7fgneaEftShUZNUMpFukGWU5ZY4Fs28Nc4kl0umSOahM1XKPs1fFg3C7FVfBLSlvmpb1M4+993oYPibHSmct1brqGq/vEOWR74tuwEUZ4h95EBBVPRSuXO7/kcmNqfGrITjjN5Y4uhe5pTVl387+TR7XOpE0uDubjBTX6YHqB3smg/asl8pOg8KHqF2TKLjgl54GMi2PajepHPLNQbSCj6WTGZbLida8/oXq+TVi0fxRKkWA+APtmisnLSP4iitpbaw="
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

