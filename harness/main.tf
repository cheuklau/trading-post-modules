provider "aws" {
  region  = "us-west-2"
  version = "~> 2.25.0"
}

terraform {
  backend "s3" {}
  required_version = ">=0.12.3"
}

resource "aws_autoscaling_group" "harness" {
  launch_configuration      = aws_launch_configuration.harness.id
  availability_zones        = ["us-west-2a", "us-west-2b", "us-west-2c"]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  min_size                  = var.min_size
  max_size                  = var.max_size
  force_delete              = true
  tag {
    key                 = "Name"
    value               = "harness"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "harness" {
  image_id             = var.ami_id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.asg.id]
  key_name             = "trading-post"
  iam_instance_profile = "ec2-role-to-access-s3"
  user_data = <<-EOF
              #!/bin/bash
              aws s3 cp s3://mtgtradingpost-harness/harness-delegate.tar .
              tar -xvf harness-delegate.tar
              cd harness-delegate
              ./start.sh
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "asg" {
  name = "harness-asg"
}

resource "aws_security_group_rule" "asg_allow_all_outbound" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks        = ["0.0.0.0/0"]
  security_group_id  = aws_security_group.asg.id
}
