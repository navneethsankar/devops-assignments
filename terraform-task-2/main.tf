terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
    tls = {
        source = "hashicorp/tls"
    }
    local = {
        source = "hashicorp/local"
    }
  }
}

provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"
}

provider "aws" {
  alias  = "singapore"
  region = "ap-southeast-1"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  filename = "terraform-key.pem"
  content = tls_private_key.ssh_key.private_key_pem
  file_permission = "0400"  
}

resource "aws_key_pair" "generated" {
  provider   = aws.mumbai
  key_name   = "terraform-generated-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_key_pair" "generated_singapore" {
  provider   = aws.singapore
  key_name   = "terraform-generated-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_security_group" "mumbai_sg" {
    provider = aws.mumbai
    name        = "mumbai-sg"
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

resource "aws_security_group" "singapore_sg" {
    provider = aws.singapore
    name        = "singapore-sg"
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

resource "aws_instance" "mumbai_instance" {
    provider = aws.mumbai
    ami    = "ami-006f82a1d5a27da54"
    instance_type = "t3.micro"
    tags = {
        Name = "Mumbai-Instance"
    }
    key_name      = aws_key_pair.generated.key_name
    vpc_security_group_ids = [aws_security_group.mumbai_sg.id]
    connection {
    type = "ssh"
    user = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host = self.public_ip
  }

provisioner "remote-exec" {
  inline = [ 
    "sudo apt update",
    "sudo apt install -y nginx",
    "sudo systemctl start nginx",
    "sudo systemctl enable nginx"
  ] 
}
}

resource "aws_instance" "singapore_instance" {
    provider = aws.singapore
    ami    = "ami-03acbba64aef9bf5c"
    instance_type = "t3.micro"
    tags = {
        Name = "Singapore-Instance"
    }
    key_name      = aws_key_pair.generated_singapore.key_name
    vpc_security_group_ids = [aws_security_group.singapore_sg.id]
    connection {
    type = "ssh"
    user = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host = self.public_ip
  }

provisioner "remote-exec" {
  inline = [ 
    "sudo apt update",
    "sudo apt install -y nginx",
    "sudo systemctl start nginx",
    "sudo systemctl enable nginx"
  ]
  
}
}



























