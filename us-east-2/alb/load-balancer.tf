resource "aws_security_group" "this" {
  name        = "kibana-alb-sg"
  description = "Allow public inbound traffic to ALB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_from_internet" {
  security_group_id = aws_security_group.this.id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_from_internet" {
  security_group_id = aws_security_group.this.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "180.254.78.9/32"
}

resource "aws_lb" "kibana_alb" {
  name               = "kibana-public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]

  subnets = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "kibana_tg" {
  name        = "kibana-target-group"
  port        = 5601
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/api/status"
    port                = "5601"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_listener" "kibana_listener" {
  load_balancer_arn = aws_lb.kibana_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana_tg.arn
  }
}

# resource "aws_lb_listener" "kibana_listener_https" {
#   load_balancer_arn = aws_lb.kibana_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.kibana_tg.arn
#   }
# }

resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.kibana_tg.arn
  target_id        = data.terraform_remote_state.kibana.outputs.instance_id
  port             = 5601
}


resource "aws_vpc_security_group_ingress_rule" "allow_connection_from_bastion" {
  security_group_id = data.terraform_remote_state.kibana.outputs.security_group_id
  referenced_security_group_id = aws_security_group.this.id

  from_port   = 5601
  to_port     = 5601
  ip_protocol = "tcp"
}
