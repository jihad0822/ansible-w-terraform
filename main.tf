locals {
  vpc_id           = "vpc-0fcbd583dd4dba6a7"
  subnet_id        = "subnet-0ea515115ece970fe"
  ssh_user         = "ubuntu"
  key_name         = "devops-ansible"
  private_key_path = "/Users/jihadmuhammad/downloads/devops-ansible.pem"
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "nginx" {
  name   = "nginx_access"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["184.191.117.91/32"] # Your IPv4 address
    # Optionally include IPv6 if still needed
    ipv6_cidr_blocks = ["2600:8806:3512:9900:388f:da28:180b:d5a5/128"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                         = "ami-0d1b5a8c13042c939"
  subnet_id                   = local.subnet_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.nginx.id] # Fixed typo from "Tron .id"
  key_name                    = local.key_name
  depends_on                  = [aws_security_group.nginx]

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = self.public_ip
      timeout     = "10m" # Increased timeout
    }
  }

  provisioner "local-exec" {
    command     = "ansible-playbook -i ${self.public_ip}, --private-key ${local.private_key_path} nginx.yaml"
    working_dir = "${path.module}"
  }
}

output "nginx_ip" {
  value = aws_instance.nginx.public_ip
}