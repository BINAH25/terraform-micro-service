resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policies" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy" "ecs_exec_inline" {
  name = "${var.name}-ecs-exec"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:StartSession",
          "ssm:TerminateSession"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.name}/log-router"
  retention_in_days = 7
}
resource "aws_ecs_task_definition" "micro_service_td" {
  family                   = var.family
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    # FireLens log router container
    {
      name      = "log-router"
      image     = "grafana/fluent-bit-plugin-loki:latest"
      essential = true
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
        }
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.name}/log-router"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "firelens"
        }
      }
    },

    {
      name      = var.container_name
      image     = var.container_image
      portMappings = var.container_port != null ? [{
        containerPort = var.container_port
        hostPort      = var.container_port
      }] : null
      environment = concat(
        var.environment,
        [
          {
            name  = "SECRET_NAME"
            value = var.secret_name
          },
          {
            name  = "AWS_REGION"
            value = var.aws_region
          },
          {
            name  = "JAEGAR_URL"
            value = var.jeager_url
          },
          {
            name  = "JAEGAR_PORT"
            value = var.jeager_port
          },
          {
            name  = "RABBIT_MQ_URL"
            value = var.rabbit_mq_url
          }
        ]
      )

      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name       = "loki" 
          Host            = "loki.seyram.site"
          Port            = "443"
          tls          = "on"
          uri        = "/loki/api/v1/push"
          label_keys   = "$container_name,$ecs_task_definition,$source,$ecs_cluster"
          remove_keys = "container_id,ecs_task_arn"
          line_format = "key_value"
        }
      }
      systemControls = []
    }
  ])

  depends_on = [aws_cloudwatch_log_group.ecs_log_group]
}


resource "aws_ecs_service" "cluster_service" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.micro_service_td.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count
  enable_execute_command = true

  network_configuration {
    subnets         = var.subnets
    security_groups = var.security_groups
    assign_public_ip =  var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.enable_load_balancer ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  depends_on = [
    aws_ecs_task_definition.micro_service_td,
    aws_iam_role_policy_attachment.ecs_task_execution_policies,
    aws_iam_role_policy_attachment.secrets_access,
    aws_iam_role_policy.ecs_exec_inline
  ]
}
