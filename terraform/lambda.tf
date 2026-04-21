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
  signature_validity_period {
    value = 135
    type  = "DAYS"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_code_signing_config" "lambda_code_signing" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_signing_profile.version_arn]
  }
  
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_secretsmanager_secret" "lambda_credentials" {
  name = "${local.resource_prefix.value}-lambda-credentials"
}

resource "aws_cloudwatch_metric_alarm" "code_signing_failures" {
  alarm_name          = "lambda-code-signing-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CodeSigningValidationFailed"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors failed code signing validations"
  dimensions = {
    FunctionName = aws_lambda_function.analysis_lambda.function_name
  }
}

resource "aws_lambda_function" "analysis_lambda" {
  filename      = "resources/lambda_function_payload.zip"
  function_name = "${local.resource_prefix.value}-analysis"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "exports.test"

  source_code_hash = "${filebase64sha256("resources/lambda_function_payload.zip")}"
  
  code_signing_config_arn = aws_lambda_code_signing_config.lambda_code_signing.arn

  runtime = "nodejs12.x"

  environment {
    variables = {
      SECRETS_MANAGER_ARN = aws_secretsmanager_secret.lambda_credentials.arn
    }
  }
}
