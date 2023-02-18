terraform {
  backend "s3" {
    bucket = "terra-aws-18"
    key    = "terraform"
    region = "us-east-1"
  }
}
