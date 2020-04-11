provider "aws" {
  region  = "us-west-2"
  version = "~> 2.25.0"
}

terraform {
  backend "s3" {}
  required_version = ">=0.12.3"
}

resource "aws_db_instance" "mtgtradingpostdb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "9.5.19"
  instance_class       = "db.t2.medium"
  name                 = "mtgtradingpostdb"
  username             = "postgres"
  password             = "password"
  skip_final_snapshot  = "true"
}
