resource "aws_s3_bucket" "ssh_public_keys" {
  bucket_prefix = "ssh-keys-"
}

resource "aws_s3_bucket_acl" "ssh_public_keys" {
  bucket = aws_s3_bucket.ssh_public_keys.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "ssh_public_keys" {
  bucket = aws_s3_bucket.ssh_public_keys.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.ssh_public_keys.arn,
          "${aws_s3_bucket.ssh_public_keys.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })
}

resource "aws_s3_object" "ssh_public_keys" {
  bucket = aws_s3_bucket.ssh_public_keys.bucket
  key    = "authorized_keys"

  content = join(
    "",
    [
      for name in var.authorized_key_names :
      "# ${name}\n${file("${var.authorized_keys_directory}/${name}.pub")}\n"
    ]
  )
  acl = "private"
}
