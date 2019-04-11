#---
# S3
#---

resource "aws_s3_bucket" "dinopark" {
  bucket = "dinopark-${var.environment}"
  acl    = "private"

  tags {
    Name   = "dinopark-${var.environment}"
    env    = "${var.environment}"
  }
}

resource "aws_s3_bucket" "dinopark-exports" {
  bucket = "dinopark-exports-${var.environment}"
  acl    = "private"

  tags {
    Name   = "dinopark-exports-${var.environment}"
    env    = "${var.environment}"
  }
}

resource "aws_s3_bucket" "dinopark-orgchart" {
  bucket = "dinopark-orgchart-${var.environment}"
  acl    = "private"

  tags {
    Name   = "dinopark-orgchart-${var.environment}"
    env    = "${var.environment}"
  }
}


