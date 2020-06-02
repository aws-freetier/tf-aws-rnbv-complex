###
# purpose of the asg module
# - setup autoscaling group for atlantis to listen github webhook
# - apply infrastructure changes using terraform
# - open inbound ports: 22(ssh), 4141(atlantis)
###
resource "aws_launch_configuration" "this" {
  image_id      = var.image_id
  instance_type = var.instance_type
  //  https://github.com/terraform-providers/terraform-provider-aws/issues/8480
  security_groups      = var.security_groups
  key_name             = var.key_name
  user_data            = var.user_data
  iam_instance_profile = var.iam_instance_profile

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  launch_configuration = aws_launch_configuration.this.id
  vpc_zone_identifier  = var.subnet_ids

  target_group_arns = [var.target_group_atlantis_arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = var.cluster_name
  }
}
