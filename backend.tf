terraform {
  backend "s3" {
    bucket = "cuame-bucket"
    key    = "path/to/my/key"
    region = "eu-west-1"
  }
}
