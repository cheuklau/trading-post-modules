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

variable "elb_port" {
  description = "Port number ELB should listen on for HTTP requests"
  type        = number
}

variable "hosted_zone_id" {
  description = "Hosted zone ID"
  type        = string
}
