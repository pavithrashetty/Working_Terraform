terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

## Create an S3 bucket
resource "aws_s3_bucket" "s3_creation" {
  bucket = var.bucket_name
  tags = {
    Name = "Pavi bucket from tf"
  }
}
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = var.bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

## Create an S3 Object referencing the file at "./build/libs/g-hello-0.0.1-SNAPSHOT.jar"
resource "aws_s3_object" "jar_upload" {
  bucket      = var.bucket_name
  key         = "g-hello-0.0.1-SNAPSHOT.jar"
  source      = var.file_location
  depends_on  = [aws_s3_bucket.s3_creation]
  source_hash = filemd5(var.file_location) #if we need versioning
}

#Create a security group for the EC2 instance
resource "aws_security_group" "ec2_g-hello_sg" {
  name = "pavi_ec2_g-hello_sg"

  #Incoming traffic
  ingress {
    description = "Allow SSH inbound traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #replace it with your ip address
  }
  ingress {
    description = "Allow HTTP inbound traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Pavi g-hello sg"
  }
}

#create an IAM Role that allows the EC2 instance to assume the role and access other AWS services.
resource "aws_iam_role" "ec2_role" {
  name = "pavi_ec2_role"
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
      }
    ]
  })
}

#The role needs a policy that defines the permissions that the EC2 instance will have when it assumes the role.
resource "aws_iam_role_policy" "ec2_role_policy" {
  name = "pavi_ec2_role_policy"
  role = aws_iam_role.ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListAllMyBuckets",
          "s3:GetObject"
        ]
        Resource= [
          "arn:aws:s3:::pavi-g-hello-tf",
          "arn:aws:s3:::pavi-g-hello-tf/*"
        ]
        Effect = "Allow"
      },
        {
          Effect = "Allow"
          Action: "s3:ListAllMyBuckets",
          Resource = "*"                     
      }
    ]
  })
}

#Create IAM instance profile to associate with ec2 role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "pavi_ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

#Create EC2 instance 
resource "aws_instance" "ec2_g-hello" {
  ami                  = "ami-0cf7b2f456cd5efd4"
  instance_type        = "t2.micro"
  key_name             = "pavi-aws_ec2_instance"
  security_groups      = ["pavi_ec2_g-hello_sg"]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.id
  # depends_on           = [aws_s3_object.jar_upload]

  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y java-17-amazon-corretto-headless
aws s3api get-object --bucket "pavi-g-hello-tf" --key "g-hello-0.0.1-SNAPSHOT.jar" "g-hello-0.0.1-SNAPSHOT.jar"
java -jar g-hello-0.0.1-SNAPSHOT.jar
EOF

  lifecycle {
    replace_triggered_by = [
      # Replace `aws_instance` each time .jar file changes
      aws_s3_object.jar_upload.source_hash
    ]
  }

  tags = {
    Name = var.instance_name
  }
}