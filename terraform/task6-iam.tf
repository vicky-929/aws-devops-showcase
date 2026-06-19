resource "aws_iam_policy" "tagged_launch_only" {
  name = "${var.environment}-accounty-tagged-launch-only"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowLaunchOnlyIfTaggedForDBAccess"
        Effect   = "Allow"
        Action   = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Access" = "db"
          }
        }
      },
      {
        # RunInstances also touches these resource types even though it's
        # not creating/tagging them - they need to be explicitly allowed
        # separately, with no tag condition, or every launch fails
        Sid    = "AllowSupportingResourcesForLaunch"
        Effect = "Allow"
        Action = "ec2:RunInstances"
        Resource = [
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:subnet/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*::image/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "automation" {
  name = "${var.environment}-accounty-automation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "automation_tagged_launch" {
  role       = aws_iam_role.automation.name
  policy_arn = aws_iam_policy.tagged_launch_only.arn
}

resource "aws_iam_role" "y_app_ssm" {
  name = "${var.environment}-accounty-app-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "y_app_ssm" {
  role       = aws_iam_role.y_app_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "y_app_ssm" {
  name = "${var.environment}-accounty-app-ssm-profile"
  role = aws_iam_role.y_app_ssm.name
}
