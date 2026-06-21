resource "aws_ecs_task_definition" "users" {
  family                   = "${var.environment}-users"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name         = "users"
      image        = "nginxdemos/hello" # public demo image - returns hostname + a visible "hello" page, easy to verify routing
      essential    = true
      portMappings = [{ containerPort = 80, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.users.name
          "awslogs-region"        = var.primary_region
          "awslogs-stream-prefix" = "users"
        }
      }
    },
    {
      name         = "xray-daemon"
      image        = "amazon/aws-xray-daemon"
      essential    = false
      portMappings = [{ containerPort = 2000, protocol = "udp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.users.name
          "awslogs-region"        = var.primary_region
          "awslogs-stream-prefix" = "xray"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "orders" {
  family                   = "${var.environment}-orders"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name         = "orders"
      image        = "hashicorp/http-echo"
      essential    = true
      command      = ["-text=orders service response", "-listen=:5678"]
      portMappings = [{ containerPort = 5678, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orders.name
          "awslogs-region"        = var.primary_region
          "awslogs-stream-prefix" = "orders"
        }
      }
    },
    {
      name         = "xray-daemon"
      image        = "amazon/aws-xray-daemon"
      essential    = false
      portMappings = [{ containerPort = 2000, protocol = "udp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orders.name
          "awslogs-region"        = var.primary_region
          "awslogs-stream-prefix" = "xray"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "users" {
  name            = "${var.environment}-users-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.users.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.network_primary.public_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true # public subnets, no NAT gateway in this setup - tasks need a public IP to pull images
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.users.arn
    container_name   = "users"
    container_port   = 80
  }
  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  depends_on = [aws_lb_listener.http]

}

resource "aws_ecs_service" "orders" {
  name            = "${var.environment}-orders-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.orders.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.network_primary.public_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.orders.arn
    container_name   = "orders"
    container_port   = 5678
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_codedeploy_app" "users" {
  name             = "${var.environment}-users-app"
  compute_platform = "ECS"
}

resource "aws_iam_role" "codedeploy" {
  name = "${var.environment}-codedeploy-ecs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_codedeploy_deployment_group" "users" {
  app_name               = aws_codedeploy_app.users.name
  deployment_group_name  = "${var.environment}-users-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes" # canary: 10% traffic first, full shift after 5 min if healthy

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.users.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]
      }
      target_group {
        name = aws_lb_target_group.users.name
      }
      target_group {
        name = aws_lb_target_group.users_green.name
      }
    }
  }
}
