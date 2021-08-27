data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "realm" {
    name = "realm_ec2"

    assume_role_policy = data.aws_iam_policy_document.ec2_trust.json

    managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
}

resource "aws_iam_instance_profile" "realm" {
    name = aws_iam_role.realm.name
    role = aws_iam_role.realm.name
}
