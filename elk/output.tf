output "elk-endpoint" {
    value = "${aws_elb.elk.public_ip}"
}