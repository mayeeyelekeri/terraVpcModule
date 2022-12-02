variable "aws_region" {
  default = "us-east-1"
}

variable "open_cidr" {
	default = "0.0.0.0/0"
}

variable "vpc_cidr" {
	default = "10.0.0.0/16"
}

variable "public_subnet_map" {
}
