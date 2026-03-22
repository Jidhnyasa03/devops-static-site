terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = var.aws_region }

resource "aws_key_pair" "devops_key" {
  key_name   = "devops-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "devops_sg" {
  name = "devops-sg"
  ingress { from_port=22   to_port=22   protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=8080 to_port=8080 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=80   to_port=80   protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=3000 to_port=3000 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=9090 to_port=9090 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=9100 to_port=9100 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=6443 to_port=6443 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0    to_port=0    protocol="-1"  cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_instance" "devops_server" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  tags = { Name = "devops-server" }
}

resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  index_document { suffix = "index.html" }
  error_document { key    = "error.html" }
}

resource "aws_s3_bucket_policy" "website" {
  bucket     = aws_s3_bucket.website.id
  depends_on = [aws_s3_bucket_public_access_block.website]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.website.arn}/*"
    }]
  })
}

output "ec2_public_ip"  { value = aws_instance.devops_server.public_ip }
output "website_url"    { value = aws_s3_bucket_website_configuration.website.website_endpoint }
output "s3_bucket_name" { value = aws_s3_bucket.website.bucket }
