resource "aws_elasticsearch_domain" "monitoring-framework" {
  domain_name           = "tg-${var.environment}-es"
  elasticsearch_version = "2.3"

  cluster_config {
    instance_type            = "t2.small.elasticsearch"
    instance_count           = 1
    dedicated_master_enabled = false
    dedicated_master_type    = "m4.large.elasticsearch"
    dedicated_master_count   = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 30
  }
}

data aws_iam_policy_document "policy" {
  statement {
    actions   = [
      "es:ESHttpGet",
      "es:DescribeElasticsearchDomain"
    ]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/specific-application-role"
      ]
    }
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/specific-domain-name"
    ]
    
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["10.0.0.0/8"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = ["vpce-specific-endpoint-id"]
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


resource "aws_elasticsearch_domain_policy" "monitoring-framework-policy" {
  domain_name = aws_elasticsearch_domain.monitoring-framework.domain_name
  access_policies = data.aws_iam_policy_document.policy.json
}
