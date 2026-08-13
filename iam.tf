data "aws_iam_policy_document" "bastion_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${var.name}-bastion"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume_role.json
}

data "aws_iam_policy_document" "bastion_authorized_keys" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ssh_public_keys.arn}/${aws_s3_object.ssh_public_keys.key}"]
  }
}

resource "aws_iam_role_policy" "bastion_authorized_keys" {
  name   = "authorized-keys-read"
  role   = aws_iam_role.bastion.id
  policy = data.aws_iam_policy_document.bastion_authorized_keys.json
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-bastion"
  role = aws_iam_role.bastion.name
}
