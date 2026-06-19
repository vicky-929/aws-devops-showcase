# Outbound-only SG for the temporary build instance Image Builder spins up -
# no inbound needed since it's controlled via Systems Manager, not SSH/RDP
resource "aws_security_group" "image_builder" {
  name   = "${var.environment}-image-builder-sg"
  vpc_id = module.network_primary.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Recipe: base Windows image + the ordered list of components to apply.
# Patches first, then software, then hardening last so it's the final state.
resource "aws_imagebuilder_image_recipe" "golden_windows" {
  name         = "${var.environment}-golden-windows-recipe"
  version      = "1.0.0"
  parent_image = "arn:aws:imagebuilder:${var.primary_region}:aws:image/windows-server-2022-english-full-base-x86/x.x.x"

  component {
    component_arn = "arn:aws:imagebuilder:${var.primary_region}:aws:component/update-windows/x.x.x"
  }
  component {
    component_arn = aws_imagebuilder_component.install_iis.arn
  }
  component {
    component_arn = aws_imagebuilder_component.install_dotnet.arn
  }
  component {
    component_arn = aws_imagebuilder_component.hardening_baseline.arn
  }
}

# Infrastructure Configuration: what temporary EC2 instance does the build
resource "aws_imagebuilder_infrastructure_configuration" "golden_windows" {
  name                          = "${var.environment}-golden-windows-infra"
  instance_profile_name         = aws_iam_instance_profile.image_builder.name
  instance_types                = ["t3.medium"]
  subnet_id                     = module.network_primary.public_subnet_ids[0]
  security_group_ids            = [aws_security_group.image_builder.id]
  terminate_instance_on_failure = true
}

# Distribution Configuration: where the finished AMI gets copied, and how
# it's encrypted in each destination region
resource "aws_imagebuilder_distribution_configuration" "golden_windows" {
  name = "${var.environment}-golden-windows-distribution"

  distribution {
    region = var.primary_region
    ami_distribution_configuration {
      name       = "${var.environment}-golden-windows-{{ imagebuilder:buildDate }}"
      kms_key_id = aws_kms_key.golden_ami.arn
    }
  }

  distribution {
    region = var.secondary_region
    ami_distribution_configuration {
      name       = "${var.environment}-golden-windows-{{ imagebuilder:buildDate }}"
      kms_key_id = aws_kms_key.golden_ami_secondary.arn
    }
  }
}

# Pipeline: ties recipe + infra + distribution together. No build yet -
# this just registers the pipeline definition.
resource "aws_imagebuilder_image_pipeline" "golden_windows" {
  name                             = "${var.environment}-golden-windows-pipeline"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden_windows.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.golden_windows.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.golden_windows.arn
}

# This is the resource that actually triggers a build - apply will block
# until it completes (or times out)
resource "aws_imagebuilder_image" "golden_windows" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden_windows.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.golden_windows.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.golden_windows.arn

  timeouts {
    create = "90m"
  }
}
