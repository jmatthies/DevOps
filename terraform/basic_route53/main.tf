terraform {
  backend "s3" {
    bucket         = "jmatthies-terraform-state"
    key            = "terraform.tfstate"
    dynamodb_table = "dev"
    region         = "us-east-1"
  }
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_vpc" "basic" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.basic.id}"
}

// resource "aws_route" "internet_access" {
//   route_table_id         = "${aws_vpc.basic.main_route_table_id}"
//   destination_cidr_block = "0.0.0.0/0"
//   gateway_id             = "${aws_internet_gateway.default.id}"
// }

resource "aws_route_table" "internet_access" {
  vpc_id                 = "${aws_vpc.basic.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.basic.id}"
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
}

variable "home_cidr" {
    default = "67.173.244.210/32"
}
resource "aws_security_group" "homessh_vpc" {
  name        = "homessh_vpc"
  description = "ssh from home only and vpc traffic"
  vpc_id      = "${aws_vpc.basic.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.home_cidr}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// resource "aws_security_group" "elb" {
//   name        = "example_elb"
//   description = ""
//   vpc_id      = "${aws_vpc.basic.id}"

//   # HTTP access from anywhere
//   ingress {
//     from_port   = 80
//     to_port     = 80
//     protocol    = "tcp"
//     cidr_blocks = ["0.0.0.0/0"]
//   }

//   # outbound internet access
//   egress {
//     from_port   = 0
//     to_port     = 0
//     protocol    = "-1"
//     cidr_blocks = ["0.0.0.0/0"]
//   }
// }

// resource "aws_elb" "web" {
//   name = "web-elb"

//   subnets         = ["${aws_subnet.default.id}"]
//   instances       = ["${aws_instance.web.id}"]
//   security_groups = ["${aws_security_group.elb.id}"]


//   listener {
//     instance_port     = 80
//     instance_protocol = "http"
//     lb_port           = 80
//     lb_protocol       = "http"
//   }
// }