resource "aws_security_group" "alb" {
  name   = "alb"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "fargate" {
  name   = "fargate"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "rds" {
  name   = "rds"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "efs" {
  name   = "efs"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.fargate.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}

resource "aws_vpc_security_group_ingress_rule" "fargate_http" {
  security_group_id            = aws_security_group.fargate.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "fargate_egress_https" {
  security_group_id            = aws_security_group.fargate.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "fargate_egress_rds" {
  security_group_id            = aws_security_group.fargate.id
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "fargate_egress_efs" {
  security_group_id            = aws_security_group.fargate.id
  referenced_security_group_id = aws_security_group.efs.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.fargate.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = aws_security_group.fargate.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}

resource "aws_security_group" "vpc_endpoints" {
  name   = "vpc-endpoints"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_egress_rule" "fargate_egress_s3" {
  security_group_id = aws_security_group.fargate.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.fargate.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}
