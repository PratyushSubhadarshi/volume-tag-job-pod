module "ebs-tags-irsa" {
  source         = "git@github.com:plivo/terraform-aws-eks-irsa-module.git?ref=v0.0.11"
  cluster_name   = var.cluster_name
  namespace      = "devops"
  serviceaccount = "pvs-tagging"
  role_name      = "eks-${var.region}-ebs-k8s-tagging"
  role_path      = "/eks/us-west-1/dev/devops/"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "ebs_tags_policy" {
  role = module.ebs-tags-irsa.role_id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeVolumes"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateTags"
        ],
        "Resource": "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:volume/*",
        "Condition": {
          "StringEqualsIfExists": {
            "ec2:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
            "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
          }
        }
      }
    ]
  })
}
