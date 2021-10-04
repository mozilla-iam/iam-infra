resource "aws_db_instance" "cis-prod" {
  identifier                  = "cis-vault-identity-prod"
  allocated_storage           = 5
  max_allocated_storage       = 20
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "11.12"
  instance_class              = "db.t2.micro"
  username                    = "cis"
  password                    = "oneTimePassword"
  parameter_group_name        = "default.postgres11"
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  db_subnet_group_name        = aws_db_subnet_group.cis-prod-db.name
  skip_final_snapshot         = "true"
  vpc_security_group_ids      = [aws_security_group.allow-psql.id]
}

resource "aws_db_subnet_group" "cis-prod-db" {
  name       = "cis-prod-db-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "cis-stage" {
  identifier                  = "cis-vault-identity-stage"
  allocated_storage           = 5
  max_allocated_storage       = 20
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "11.12"
  instance_class              = "db.t2.micro"
  username                    = "cis"
  password                    = "oneTimePassword"
  parameter_group_name        = "default.postgres11"
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  db_subnet_group_name        = aws_db_subnet_group.cis-stage-db.name
  skip_final_snapshot         = "true"
  vpc_security_group_ids      = [aws_security_group.allow-psql.id]
}

resource "aws_db_subnet_group" "cis-stage-db" {
  name       = "cis-stage-db-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "cis-dev" {
  identifier                  = "cis-vault-identity-dev"
  allocated_storage           = 5
  max_allocated_storage       = 20
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "11.12"
  instance_class              = "db.t2.micro"
  username                    = "cis"
  password                    = "oneTimePassword"
  parameter_group_name        = "default.postgres11"
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  db_subnet_group_name        = aws_db_subnet_group.cis-dev-db.name
  skip_final_snapshot         = "true"
  vpc_security_group_ids      = [aws_security_group.allow-psql.id]
}

resource "aws_db_subnet_group" "cis-dev-db" {
  name       = "cis-dev-db-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "allow-psql" {
  name        = "allow_psql_from_k8s_workers"
  description = "Allow traffic to PSQL from Kubernetes prod workers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.worker_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_psql_from_k8s_prod_workers"
  }
}

