resource "aws_iam_role" "iam_for_lambda" {
  name = "${local.resource_prefix.value}-analysis-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_signer_signing_profile" "lambda_signing_profile" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "${local.resource_prefix.value}-lambda-signing-profile"
  
  signature_validity_period {
    value = 1
    type  = "YEARS"
  }

  tags = {
    SecurityCompliance = "CodeSigningEnabled"
    RotationRequired   = "Annual"
  }
}

resource "aws_lambda_code_signing_config" "lambda_code_signing" {
  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.lambda_signing_profile.version_arn
    ]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }

  description = "Code signing configuration for ${local.resource_prefix.value}-analysis Lambda"

  tags = {
    Purpose            = "LambdaCodeSigning"
    EnforcementLevel   = "Strict"
    ComplianceControl  = "BC-AWS-272"
  }
}

resource "aws_secretsmanager_secret" "lambda_secrets" {
  name = "${local.resource_prefix.value}-lambda-secrets"
}

resource "aws_secretsmanager_secret_version" "lambda_secrets_version" {
  secret_id = aws_secretsmanager_secret.lambda_secrets.id
  secret_string = jsonencode({
    access_key = "AKIAIOSFODNN7EXAMPLE"
    secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  })
}

resource "aws_lambda_function" "analysis_lambda" {
  filename      = "resources/lambda_function_payload.zip"
  function_name = "${local.resource_prefix.value}-analysis"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "exports.test"

  source_code_hash = filebase64sha256("resources/lambda_function_payload.zip")

  runtime = "nodejs12.x"

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_code_signing.arn

  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.lambda_secrets.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_lambda_code_signing_config.lambda_code_signing,
    aws_signer_signing_profile.lambda_signing_profile
  ]

  lifecycle {
    prevent_destroy = true
  }
}
