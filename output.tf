output "alb_sg_id" {
  value = "${aws_security_group.alb_sg.id}"
}

output "alb_dns_name" {
  value = "${module.alb.dns_name}"
}

output "nlb_dns_record" {
  value = "${aws_route53_record.nlb_record.fqdn}"
}
