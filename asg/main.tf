provider "aws" {
  region  = "us-west-2"
  version = "~> 2.25.0"
}

terraform {
  backend "s3" {}
  required_version = ">=0.12.3"
}

resource "aws_autoscaling_group" "mtgtradingpost" {
  launch_configuration      = aws_launch_configuration.mtgtradingpost.id
  availability_zones        = ["us-west-2a", "us-west-2b", "us-west-2c"]
  load_balancers            = [aws_elb.mtgtradingpost.name]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = var.min_size
  max_size                  = var.max_size
  force_delete              = true
  tag {
    key                 = "Name"
    value               = "mtgtradingpost"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "mtgtradingpost" {
  image_id        = data.aws_ami.mtgtradingpost.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.asg.id]
  user_data       = <<-EOF
              #!/bin/bash
              cd /var/www/FlaskApp/
              sudo sed -i "s/create_engine('sqlite:\/\/\/catalog.db')/create_engine('postgresql:\/\/postgres:password@${data.terraform_remote_state.aws_db_instance.address}\/mtgtradingpostdb')/g" `find . -maxdepth 1 -type f`
              sudo python database_setup.py
              sudo python populate_db.py
              sudo a2ensite FlaskApp
              sudo service apache2 restart
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

data "terraform_remote_state" "aws_db_instance" {
  backend = "remote"
  filter {
    name   = "name"
    values = ["mtgtradingpostdb"]
  }
}

data "aws_ami" "mtgtradingpost" {
  most_recent = true
  owners      = ["650716339685"]
  filter {
    name   = "name"
    values = ["trading-app-v2-*"]
  }
}

resource "aws_security_group" "asg" {
  name = "mtgtradingpost-asg"
}

resource "aws_security_group_rule" "asg_allow_http_inbound_from_elb" {
  type      = "ingress"
  from_port = var.server_port
  to_port   = var.server_port
  protocol  = "tcp"
  # cidr_blocks       = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.asg.id
  source_security_group_id = aws_security_group.elb.id
}

resource "aws_elb" "mtgtradingpost" {
  name               = "mtgtradingpost"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  security_groups    = [aws_security_group.elb.id]
  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "mtgtradingpost-elb"
}

resource "aws_security_group_rule" "elb_allow_http_inbound" {
  type              = "ingress"
  from_port         = var.elb_port
  to_port           = var.elb_port
  protocol          = "tcp"
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
