
provider "aws" {
  region = var.region
}

resource "tls_private_key" "custom_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "custom_key" {
  content = tls_private_key.custom_key.private_key_pem
  filename = "CustomKey.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "custom_key" {
  key_name = "CustomKey"
  public_key = tls_private_key.custom_key.public_key_openssh
}

# VPC ID: 

data "aws_vpc" "main" {
  id = var.vpc_id
}


resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound everywhere"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv6" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv6         = "::/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_rdp_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3389
  ip_protocol       = "tcp"
  to_port           = 3389
}

resource "aws_vpc_security_group_ingress_rule" "allow_rdp_ipv6" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv6         = "::/0"
  from_port         = 3389
  ip_protocol       = "tcp"
  to_port           = 3389
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "linux" {
  # Debian ami
  ami           = var.ami
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  user_data = file("sshify.sh")

  key_name = aws_key_pair.custom_key.key_name
  
  # wait until the user script is done, so we can ssh into this "properly"
  provisioner "remote-exec" {
    connection {
      agent = false
      host = self.public_ip
      private_key = tls_private_key.custom_key.private_key_pem
      target_platform = "unix"
      timeout = "10m"
      type = "ssh"
      user = "admin"
    }
    inline = [
      "while [ ! -f /tmp/userdata_done ]; do sleep 5; done",
    ]
  }

  provisioner "remote-exec" {
    connection {
      agent = false
      host = self.public_ip
      private_key = tls_private_key.custom_key.private_key_pem
      target_platform = "unix"
      timeout = "10m"
      type = "ssh"
      user = "admin"
    }

    inline = ["Write-Output 'Finished!'"]
  }
}

