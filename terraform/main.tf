provider "aws" {
  region = "sa-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-tfstate-grupo12-fiap-2025"
    key    = "infra/terraform.tfstate"
    region = "sa-east-1"
  }
}

# ECR para armazenar a imagem do projeto
resource "aws_ecr_repository" "project_repo" {
  name = "hackathon_ecr"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "hackathon-ecs-cluster"
}

# SQS processar_arquivo
resource "aws_sqs_queue" "processar_arquivo" {
  name = "sqs_processar_arquivo"
}

# S3 
resource "aws_s3_bucket" "code-bucket" {
  bucket = "hackathon-code-bucket"
}

# S3 Arquivos
resource "aws_s3_bucket" "files-bucket" {
  bucket = "hackathon-files-bucket"
}

data "aws_iam_policy_document" "queue_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:*:*:sqs_processar_arquivo"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.files-bucket.arn]
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.files-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.processar_arquivo.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}


# Criação da Tabela DynamoDB
resource "aws_dynamodb_table" "processamento_arquivo" {
  name         = "GerenciadorTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S" # Tipo da chave: "S" para string, "N" para número, "B" para binário
  }

  tags = {
    Team = "Grupo12Hackathon"
  }
}