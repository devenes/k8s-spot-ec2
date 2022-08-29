terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.myRegion
}

data "aws_caller_identity" "current" {}

#data "aws_region" "current" {}

data "template_file" "worker" { # data.template_file.worker
  template = file("worker.sh")
  vars = {
    region         = var.myRegion
    master-id      = aws_spot_instance_request.master.id
    master-private = aws_spot_instance_request.master.private_ip
  }
}

data "template_file" "master" { # data.template_file.master
  template = file("master.sh")
}

locals {
  name = "devenes" # change here, optional  # local.name = 
}

resource "aws_spot_instance_request" "master" {
  ami                  = var.myAmi
  spot_price           = "0.0200"
  instance_type        = var.master_instance_type
  availability_zone    = var.myAZs
  wait_for_fulfillment = true
  key_name             = var.myKey
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile2.name
  security_groups      = ["${local.name}-k8s-master-sec-gr"]
  user_data            = data.template_file.master.rendered
  tags = {
    Name = "${local.name}-kube-master"
  }
}

resource "aws_instance" "worker" {
  ami                  = var.myAmi
  instance_type        = var.worker_instance_type
  key_name             = var.myKey
  availability_zone    = var.myAZs
  count                = 3
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile2.name
  security_groups      = ["${local.name}-k8s-master-sec-gr"]
  user_data            = data.template_file.worker.rendered
  tags = {
    Name = "${local.name}-kube-worker-${count.index}"
  }
  depends_on = [aws_spot_instance_request.master]
}

resource "aws_iam_instance_profile" "ec2connectprofile2" {
  name = "ec2connectprofile2"
  role = aws_iam_role.ec2connectcli.name
}

resource "aws_iam_role" "ec2connectcli" {
  name = "ec2connectcli"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : "ec2-instance-connect:SendSSHPublicKey",
          "Resource" : "arn:aws:ec2:${var.myRegion}:${data.aws_caller_identity.current.account_id}:instance/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:osuser" : "ubuntu"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstances",
          "Resource" : "*"
        }
      ]
    })
  }
}

resource "aws_security_group" "tf-k8s-master-sec-gr" {
  name = "${local.name}-k8s-master-sec-gr"
  tags = {
    Name = "${local.name}-k8s-master-sec-gr"
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

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
    from_port   = 30000
    to_port     = 32767
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

/*
output "master_public_dns" {
  value = aws_spot_instance_request.master.public_dns
}

output "master_private_dns" {
  value = aws_spot_instance_request.master.private_dns
}

output "worker_public_dns" {
  value = aws_instance.worker[*].public_dns
}

output "worker_private_dns" {
  value = aws_instance.worker[*].private_dns
}
*/
