# Registers the ECS service as something Application Auto Scaling can control
resource "aws_appautoscaling_target" "users" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.users.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Horizontal scaling: target tracking on CPU - ECS automatically adds/removes
# tasks to keep average CPU near 50%
resource "aws_appautoscaling_policy" "users_cpu" {
  name               = "${var.environment}-users-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.users.resource_id
  scalable_dimension = aws_appautoscaling_target.users.scalable_dimension
  service_namespace  = aws_appautoscaling_target.users.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Horizontal scaling: target tracking on Memory too, since the task asked
# for CPU, memory, OR custom metric - this covers the memory case
resource "aws_appautoscaling_policy" "users_memory" {
  name               = "${var.environment}-users-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.users.resource_id
  scalable_dimension = aws_appautoscaling_target.users.scalable_dimension
  service_namespace  = aws_appautoscaling_target.users.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Scheduled scaling: simulates a predictable daily pattern - scale up for
# "business hours" (9 AM UTC), scale down after (6 PM UTC)
resource "aws_appautoscaling_scheduled_action" "scale_up_morning" {
  name               = "${var.environment}-scale-up-morning"
  service_namespace  = aws_appautoscaling_target.users.service_namespace
  resource_id        = aws_appautoscaling_target.users.resource_id
  scalable_dimension = aws_appautoscaling_target.users.scalable_dimension

  schedule = "cron(0 9 * * ? *)"

  scalable_target_action {
    min_capacity = 2
    max_capacity = 4
  }
}

resource "aws_appautoscaling_scheduled_action" "scale_down_evening" {
  name               = "${var.environment}-scale-down-evening"
  service_namespace  = aws_appautoscaling_target.users.service_namespace
  resource_id        = aws_appautoscaling_target.users.resource_id
  scalable_dimension = aws_appautoscaling_target.users.scalable_dimension

  schedule = "cron(0 18 * * ? *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 4
  }
}
