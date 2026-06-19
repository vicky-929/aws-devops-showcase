resource "aws_iam_role" "image_builder" {
  name = "${var.environment}-image-builder-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Lets the build instance report progress back to Image Builder
resource "aws_iam_role_policy_attachment" "image_builder_core" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

# Image Builder talks to the build instance via Systems Manager, not SSH -
# this policy is what makes that connection possible
resource "aws_iam_role_policy_attachment" "image_builder_ssm" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "image_builder" {
  name = "${var.environment}-image-builder-profile"
  role = aws_iam_role.image_builder.name
}
