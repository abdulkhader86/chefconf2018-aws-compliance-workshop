provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }

  owners = ["137112412989"]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_vpc" "workshop-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name      = "${var.lab_prefix} - VPC - ${terraform.workspace}"
    X-Contact = "${var.aws_tag_x_contact}"
  }
}

resource "aws_internet_gateway" "workshop-gw" {
  vpc_id = "${aws_vpc.workshop-vpc.id}"

  tags {
    Name      = "${var.lab_prefix} - Gateway - ${terraform.workspace}"
    X-Contact = "${var.aws_tag_x_contact}"
  }
}

resource "aws_route_table" "workshop-routes" {
  vpc_id = "${aws_vpc.workshop-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.workshop-gw.id}"
  }

  tags {
    Name      = "Route Table - ${var.lab_prefix} - ${terraform.workspace}"
    X-Contact = "${var.aws_tag_x_contact}"
  }
}

resource "aws_subnet" "workshop-subnet" {
  vpc_id     = "${aws_vpc.workshop-vpc.id}"
  cidr_block = "10.0.0.0/24"

  tags {
    Name      = "${var.lab_prefix} - Subnet - ${terraform.workspace}"
    X-Contact = "${var.aws_tag_x_contact}"
  }
}

resource "aws_route_table_association" "workshop-route_association" {
  subnet_id      = "${aws_subnet.workshop-subnet.id}"
  route_table_id = "${aws_route_table.workshop-routes.id}"
}

resource "aws_network_acl" "workshop-acl" {
  vpc_id     = "${aws_vpc.workshop-vpc.id}"
  subnet_ids = ["${aws_subnet.workshop-subnet.id}"]

  ingress {
    protocol   = -1
    rule_no    = 1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 2
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name      = "${var.lab_prefix} - ACL - ${terraform.workspace}"
    X-Contact = "${var.aws_tag_x_contact}"
  }
}

resource "aws_security_group" "workshop-sg" {
  name        = "${var.lab_prefix}-workshop-sg-${terraform.workspace}"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.workshop-vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name      = "${var.lab_prefix} - Security Group  - ${terraform.workspace}"
    X-Contact = "${var.aws_tag_x_contact}"
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "${var.lab_prefix}-admin-key-pair-${terraform.workspace}"
  public_key = "${var.ssh_public_key}"
}
