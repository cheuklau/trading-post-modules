output "asg_name" {
  value = aws_autoscaling_group.harness.name
}

output "asg_security_group_id" {
  value = aws_security_group.asg.id
}
