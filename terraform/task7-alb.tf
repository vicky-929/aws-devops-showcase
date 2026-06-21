resource "aws_lb" "main" {
  name               = "${var.environment}-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.network_primary.public_subnet_ids
}

resource "aws_lb_target_group" "users" {
  name        = "${var.environment}-users-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.network_primary.vpc_id
  target_type = "ip" # required for Fargate - tasks don't have a fixed EC2 instance to register

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }
}

resource "aws_lb_target_group" "orders" {
  name        = "${var.environment}-orders-tg"
  port        = 5678
  protocol    = "HTTP"
  vpc_id      = module.network_primary.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }
}

# Default listener - anything not matching a specific rule falls back here
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.users.arn
  }
}

# Path-based rule: anything starting with /orders goes to the orders service
resource "aws_lb_listener_rule" "orders" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orders.arn
  }

  condition {
    path_pattern {
      values = ["/orders*"]
    }
  }
}

# Explicit rule for /users too (not strictly required since it's the default,
# but makes the routing intent clear and self-documenting)
resource "aws_lb_listener_rule" "users" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.users.arn
  }

  condition {
    path_pattern {
      values = ["/users*"]
    }
  }
}

resource "aws_lb_target_group" "users_green" {
  name        = "${var.environment}-users-green-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.network_primary.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }
}
