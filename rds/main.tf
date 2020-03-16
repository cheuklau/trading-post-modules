resource "aws_db_instance" "mtgtradingpostdb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "9.5.19"
  instance_class       = "db.t2.micro"
  name                 = "mtgtradingpostdb"
  username             = "postgres"
  password             = "password"
}