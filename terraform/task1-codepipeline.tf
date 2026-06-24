# ─── S3 bucket for pipeline artifacts ────────────────────────────────────────
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket        = "${var.environment}-codepipeline-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags          = { Name = "${var.environment}-pipeline-artifacts" }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration { status = "Enabled" }
}

# ─── IAM Role for CodePipeline ───────────────────────────────────────────────
resource "aws_iam_role" "codepipeline" {
  name = "${var.environment}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  role = aws_iam_role.codepipeline.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:GetBucketVersioning",
          "s3:GetObjectVersion", "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["codedeploy:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection"]
        Resource = "*"
      }
    ]
  })
}

# ─── IAM Role for CodeDeploy ─────────────────────────────────────────────────
resource "aws_iam_role" "task1_codedeploy" {
  name = "${var.environment}-task1-codedeploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task1_codedeploy" {
  role       = aws_iam_role.task1_codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ─── CodeDeploy Application ──────────────────────────────────────────────────
resource "aws_codedeploy_app" "dotnet_app" {
  name             = "${var.environment}-dotnet-app"
  compute_platform = "Server"
}

# ─── CodeDeploy Deployment Group ─────────────────────────────────────────────
resource "aws_codedeploy_deployment_group" "dotnet_app" {
  app_name              = aws_codedeploy_app.dotnet_app.name
  deployment_group_name = "${var.environment}-dotnet-app-dg"
  service_role_arn      = aws_iam_role.task1_codedeploy.arn

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "DeployGroup"
      type  = "KEY_AND_VALUE"
      value = "dotnet-app"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

# ─── GitHub Connection ────────────────────────────────────────────────────────
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.environment}-github-connection"
  provider_type = "GitHub"
}

# ─── CodePipeline (Source → Deploy, no CodeBuild) ────────────────────────────
resource "aws_codepipeline" "dotnet_app" {
  name     = "${var.environment}-dotnet-app-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "vicky-929/aws-devops-showcase"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["source_output"]
      configuration = {
        ApplicationName     = aws_codedeploy_app.dotnet_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dotnet_app.deployment_group_name
      }
    }
  }
}

output "dotnet_pipeline_name" {
  value = aws_codepipeline.dotnet_app.name
}

output "github_connection_arn" {
  value = aws_codestarconnections_connection.github.arn
}
