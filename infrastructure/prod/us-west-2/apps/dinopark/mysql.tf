#---
# RDS MySQL database
#---

# RDS security group
resource "aws_security_group" "dinopark-mysql" {
  name        = "dinopark-mysql-${var.environment}-${var.region}"
  description = "Traffic rules for Mozillians MySQL ${var.environment} in ${var.region}"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_security_group_rule" "dinopark-mysql-ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "-1"
  cidr_blocks              = ["10.0.0.0/16"]
  security_group_id        = "${aws_security_group.dinopark-mysql.id}"
}

resource "aws_security_group_rule" "dinopark-mysql-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  # TODO check if this can be restricted to 10.0.0.0/16
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.dinopark-mysql.id}"
}

# DB Instace
resource "aws_db_instance" "mysql-dinopark-db" {
  allocated_storage          = 5
  engine                     = "mysql"
  engine_version             = "5.6.41"
  auto_minor_version_upgrade = false
  instance_class             = "db.t2.small"
  publicly_accessible        = false
  backup_retention_period    = 14
  apply_immediately          = true
  multi_az                   = true
  storage_type               = "gp2"
  final_snapshot_identifier  = "mysql-dinopark-db-final-${var.environment}-${var.region}"
  name                       = "dinoparkdb"
  username                   = "root"
  password                   = "${data.aws_ssm_parameter.dinopark-db-password.value}"
  parameter_group_name       = "default.mysql5.6"

  tags {
    Name    = "mysql-dinopark-db"
    app     = "mysql"
    env     = "${var.environment}"
    region  = "${var.region}"
    project = "dinopark"
  }
}

