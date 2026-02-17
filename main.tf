
provider "aws" {
  region = "us-east-2"
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
  id = "vpc-073cdf4b47dad4497"
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

resource "aws_instance" "windows" {
  # Windows Server 2025 Base, in us-east-2
  ami           = "ami-0594938cc69a82b95"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  user_data = file("sshify.yml")

  connection {
    agent = false
    host = self.public_ip
    private_key = tls_private_key.custom_key.private_key_pem
    script_path = "C:/Windows/Temp/opentofu_%RAND%.ps1"
    target_platform = "windows"
    timeout = "10m"
    type = "ssh"
    user = "Administrator"
  }
  key_name = aws_key_pair.custom_key.key_name
  # We need to know when the instance is up (SSH is available), so we
  # "execute" a remote dummy command
  provisioner "remote-exec" {
    inline = [
      "Write-Output 'Finished!'",
    ]
    # Using this as a workaround to circumvent the failure
    # on_failure = continue
  }
}

