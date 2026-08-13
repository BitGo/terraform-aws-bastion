resource "aws_security_group" "bastion" {
  name   = var.name
  vpc_id = var.vpc_id
  tags = {
    Name = var.name
  }
}

data "aws_iam_policy_document" "s3_bucket_access" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.bastion.arn]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.ssh_public_keys.arn}/${aws_s3_object.ssh_public_keys.key}"]
  }
}

data "aws_region" "current" {}

# IAM is eventually consistent: EC2's endpoint-policy validation can reject a
# just-created role ARN as an unknown principal with "InvalidPolicyDocument"
# if the policy is applied in the same terraform run that creates the role.
# This sleep gives the role time to propagate before the endpoint policy
# (which references aws_iam_role.bastion.arn) is created/updated.
resource "time_sleep" "wait_for_bastion_role" {
  depends_on      = [aws_iam_role.bastion]
  create_duration = "10s"
}

resource "aws_vpc_endpoint" "s3_bucket" {
  depends_on = [time_sleep.wait_for_bastion_role]

  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  policy       = data.aws_iam_policy_document.s3_bucket_access.json
}

resource "aws_security_group_rule" "s3_egress" {
  type              = "egress"
  from_port         = "0"
  to_port           = "443"
  protocol          = "TCP"
  cidr_blocks       = aws_vpc_endpoint.s3_bucket.cidr_blocks
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_ssh_ingress" {
  type              = "ingress"
  from_port         = var.ssh_port
  to_port           = var.ssh_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_all_egress" {
  count = var.create_egress_rule ? 1 : 0

  type              = "egress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "all"
  cidr_blocks       = var.allowed_egress_cidrs
  ipv6_cidr_blocks  = var.allowed_ipv6_egress_cidrs
  security_group_id = aws_security_group.bastion.id
}
