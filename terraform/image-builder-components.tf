resource "aws_imagebuilder_component" "install_iis" {
  name     = "${var.environment}-install-iis"
  platform = "Windows"
  version  = "1.0.0"
  data     = file("${path.module}/components/install-iis.yaml")
}

resource "aws_imagebuilder_component" "install_dotnet" {
  name     = "${var.environment}-install-dotnet"
  platform = "Windows"
  version  = "1.0.0"
  data     = file("${path.module}/components/install-dotnet.yaml")
}

resource "aws_imagebuilder_component" "hardening_baseline" {
  name     = "${var.environment}-org-hardening-baseline"
  platform = "Windows"
  version  = "1.0.0"
  data     = file("${path.module}/components/hardening-baseline.yaml")
}
