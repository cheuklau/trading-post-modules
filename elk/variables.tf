variable "ami_id" {
    description = "AWS Linux AMI ID"
    type        = string
}

variable "elb_port" {
    description = "AWS ELB port"
    type        = string
}

variable "instance_type" {
    description = "EC2 instance type to deploy"
    type        = string
}

variable "server_port" {
    description = "Kibana port"
    type        = string
}