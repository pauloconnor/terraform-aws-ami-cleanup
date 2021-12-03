resource "aws_iam_role" "ami_cleanup_lambda" {
  name = "${var.prefix}_ami_cleanup"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
  })

}

resource "aws_iam_role_policy" "ami_cleanup" {
  name = "${var.prefix}_ami_cleanup"
  role = aws_iam_role.ami_cleanup_lambda.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeregisterImage"
          ],
          "Resource" : "*"
        }
      ]
  })
}


resource "aws_iam_role_policy" "allowcloudwatchlogging" {
  name = "${var.prefix}_ami_cleanup_logging"
  role = aws_iam_role.ami_cleanup_lambda.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*"
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "ami_cleanup" {
  role       = aws_iam_role.ami_cleanup_lambda.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_lambda_function" "ami_cleanup" {
  filename         = "${path.module}/clean_amis.zip"
  source_code_hash = filebase64("${path.module}/clean_amis.zip")
  function_name    = "${var.prefix}_ami_cleanup"
  role             = aws_iam_role.ami_cleanup_lambda.arn
  handler          = "clean_amis.lambda_handler"
  runtime          = "python3.7"
  publish          = "true"
  timeout          = 300
  memory_size      = 128
  description      = "Runs a Python script to clean up old AMIs that are not currently in use"

  environment {
    variables = {
      ACCOUNT_ID             = var.account_id == "" ? data.aws_caller_identity.current.account_id : var.account_id
      DELETE_OLDER_THAN_DAYS = var.delete_older_than_days
      EXCLUSION_TAG          = var.exclusion_tag
      TAG_FILTER             = var.filter_tag
    }
  }
}

resource "aws_cloudwatch_event_rule" "ami_cleanup" {
  name                = "${var.prefix}_ami_cleanup"
  description         = "Fires every month"
  schedule_expression = "cron({$var.cron})"
}

resource "aws_cloudwatch_event_target" "ami_cleanup" {
  arn       = aws_lambda_function.ami_cleanup.arn
  rule      = aws_cloudwatch_event_rule.ami_cleanup.name
  target_id = "${var.prefix}_ami_cleanup"
}

resource "aws_lambda_permission" "cloudwatch_call_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ami_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ami_cleanup.arn
  statement_id  = "AllowExecutionFromCloudWatch"
}
