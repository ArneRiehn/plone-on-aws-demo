resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/plone/db_password"
  type  = "SecureString"
  value = random_password.db_password.result
}

resource "aws_ssm_parameter" "relstorage_dsn" {
  name  = "/plone/relstorage_dsn"
  type  = "SecureString"
  value = "dbname='plone' user='plone' host='${aws_db_instance.postgres_relstorage.address}' password='${random_password.db_password.result}'"
}


resource "aws_db_instance" "postgres_relstorage" {
  allocated_storage   = 20
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  db_name             = "plone"
  username            = "plone"
  password            = random_password.db_password.result
  skip_final_snapshot = true
  multi_az            = false

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
}
