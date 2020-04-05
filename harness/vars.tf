variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "ami_id" {
  description = "AWS Linux AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type to deploy"
  type        = string
}

variable "min_size" {
  description = "Minimum number of EC2 Instances to run in the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EC2 Instances to run in the ASG"
  type        = number
}

variable "server_port" {
  description = "Port number web server on each EC2 Instance should listen on for HTTP requests"
  type        = number
}
