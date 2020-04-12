provider "aws" {
  region  = "us-west-2"
  version = "~> 2.25.0"
}

terraform {
  backend "s3" {}
  required_version = ">=0.12.3"
}

resource "aws_autoscaling_group" "elk" {
  launch_configuration      = aws_launch_configuration.elk.id
  availability_zones        = ["us-west-2a", "us-west-2b", "us-west-2c"]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = 1
  max_size                  = 1
  force_delete              = true
  tag {
    key                 = "Name"
    value               = "elk"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "elk" {
  image_id             = var.ami_id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.asg.id]
  key_name             = "trading-post"
  iam_instance_profile = "ec2-role-to-access-s3"
  user_data = <<-EOF
              #!/bin/bash
              aws s3 cp s3://mtgtradingpost-elk/elasticsearch.repo /home/ec2-user/elasticsearch.repo
              aws s3 cp s3://mtgtradingpost-elk/kibana.repo /home/ec2-user/kibana.repo
              aws s3 cp s3://mtgtradingpost-elk/kibana.yml /home/ec2-user/kibana.yml
              aws s3 cp s3://mtgtradingpost-elk/logstash.repo /home/ec2-user/logstash.repo
              aws s3 cp s3://mtgtradingpost-elk/logstash.conf /home/ec2-user/logstash.conf
              sudo yum -y update
              sudo yum -y install java-1.8.0-openjdk
              sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
              sudo mv /home/ec2-user/logstash.repo /etc/yum.repos.d/
              sudo yum -y install logstash
              sudo mv /home/ec2-user/logstash.conf /etc/logstash/
              sudo mv /home/ec2-user/elasticsearch.repo /etc/yum.repos.d/
              sudo yum -y install elasticsearch
              sudo mv /home/ec2-user/kibana.repo /etc/yum.repos.d/
              sudo yum -y install kibana
              sudo mv /home/ec2-user/kibana.yml /etc/kibana/
              sudo systemctl start elasticsearch.service
              sudo nohup /usr/share/logstash/bin/logstash -f /etc/logstash/logstash.conf &
              sudo systemctl start kibana.service
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = "mtgtradingpost-terraform-state"
    key = "rds/terraform.tfstate"
    region = "us-west-2"
  }
}

resource "aws_security_group" "asg" {
  name = "elk-asg"
}

resource "aws_security_group_rule" "asg_allow_inbound_from_elb_kibana" {
  type      = "ingress"
  from_port = var.kibana_port
  to_port   = var.kibana_port
  protocol  = "http"
  security_group_id        = aws_security_group.asg.id
  source_security_group_id = aws_security_group.elb.id
}

resource "aws_security_group_rule" "asg_allow_inbound_from_filebeat" {
  type      = "ingress"
  from_port = var.logstash_port
  to_port   = var.logstash_port
  protocol  = "tcp"
  security_group_id        = aws_security_group.asg.id
  source_security_group_id = "${data.terraform_remote_state.asg.outputs.aws_security_group.id}"
}

resource "aws_security_group_rule" "asg_allow_all_outbound" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks        = ["0.0.0.0/0"]
  security_group_id  = aws_security_group.asg.id
}

resource "aws_elb" "elk" {
  name               = "elk"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  security_groups    = [aws_security_group.elb.id]
  listener {
    lb_port           = var.kibana_port
    lb_protocol       = "http"
    instance_port     = var.kibana_port
    instance_protocol = "http"
  }
  listener {
    lb_port           = var.logstash_port
    lb_protocol       = "http"
    instance_port     = var.logstash_port
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.kibana_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "elk-elb"
}

resource "aws_security_group_rule" "elb_allow_http_inbound_kibana" {
  type              = "ingress"
  from_port         = var.kibana_port
  to_port           = var.kibana_port
  protocol          = "-1"
  cidr_blocks       = ["98.234.62.159/32"] # Just my own IP for now
  security_group_id = aws_security_group.elb.id
}

resource "aws_security_group_rule" "elb_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb.id
}
