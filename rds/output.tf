output "address" {
    value = "${aws_db_instance.mtgtradingpostdb.address}"
    description = "The address of the RDS instance."
}

output "endpoint" {
    value = "${aws_db_instance.mtgtradingpostdb.endpoint}"
    description = "The connection endpoint."
}