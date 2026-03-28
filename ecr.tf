resource "aws_ecr_repository" "plone" {
  name = "plone-on-aws-demo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.plone.repository_url
}
