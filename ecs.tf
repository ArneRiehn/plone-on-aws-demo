resource "aws_ecs_cluster" "plone" {
  name = "plone"
}

resource "aws_cloudwatch_log_group" "plone" {
  name              = "/ecs/plone"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "plone" {
  family                   = "plone"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "plone"
      image     = "${aws_ecr_repository.plone.repository_url}:latest"
      cpu       = 256
      memory    = 1024
      essential = true
      environment = [
        {
          name  = "RELSTORAGE_SHARED_BLOB_DIR"
          value = "true"
        }
      ]
      secrets = [
        {
          name      = "RELSTORAGE_DSN"
          valueFrom = aws_ssm_parameter.relstorage_dsn.arn
        }
      ]
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "efs-plone-blobstorage"
          containerPath = "/data/blobstorage"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.plone.name
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "plone"
        }
      }
    }
  ])

  volume {
    name = "efs-plone-blobstorage"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.plone_blobstorage.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.plone_blobstorage.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "plone" {
  name            = "plone"
  cluster         = aws_ecs_cluster.plone.id
  task_definition = aws_ecs_task_definition.plone.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener.listener]

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "plone"
    container_port   = 8080
  }

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.fargate.id]
  }
}
