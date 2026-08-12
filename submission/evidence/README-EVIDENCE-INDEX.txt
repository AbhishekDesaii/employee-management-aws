EVIDENCE INDEX — READ THIS FIRST
=================================
All of the files below were captured from a LIVE AWS account on 2026-08-12.
The three parts were deployed with `terraform apply` and verified with curl.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 1. WHO MADE THIS (author proof)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  git-profile/git-profile.txt          Git name, email, repo, latest commits

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 2. TERRAFORM APPLY — REAL EXECUTION LOGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  apply-logs/part1-apply.log          Part 1 → "Resources: 4 added"   (single EC2)
  apply-logs/part2-apply.log          Part 2 → "Resources: 5 added"   (two EC2 + VPC)
  apply-logs/part3-apply.log          Part 3 → "Resources: 39 added"  (ECR + ECS + ALB)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 3. AWS CONSOLE-STYLE VIEWS (raw resource listings, live)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  aws-cli-output/part1-single-ec2.txt    EC2 instance + EIP + security group
  aws-cli-output/part2-separate-ec2.txt  VPC, subnet, IGW, route, instances, SGs
  aws-cli-output/part3-ecs.txt           ECR, ECS cluster/tasks, ALB, target health
  aws-cli-output/s3-remote-state.txt     S3 state bucket, versioning, DynamoDB lock

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 4. LIVE VERIFICATION — THE APPS ARE RUNNING ON AWS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  aws-cli-output/verify-part1-curl.txt   Flask :5000 /api/health + Express :3000 page
  aws-cli-output/verify-part2-curl.txt   Flask :5000 (backend) + Express :3000 (frontend)
                                         + cross-instance request over private IP 10.0.0.95
  aws-cli-output/verify-part3-curl.txt   ALB → /api/health (Flask) + / (Express)
                                         + POST employee + GET list  (201 / 200)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 5. HUMAN-READABLE PNG VIEWS (rendered from the above)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  screenshots/part1-single-ec2.png
  screenshots/part2-separate-ec2.png
  screenshots/part3-ecs.png
  screenshots/s3-remote-state.png
  screenshots/verify-part1.png
  screenshots/verify-part2.png
  screenshots/verify-part3.png

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 6. REAL BROWSER SCREENSHOTS OF THE RUNNING APPLICATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app-screenshots/part1-frontend.png          Express home page (Part 1)
  app-screenshots/part1-employees.png         Employees page fetched via Flask (Part 1)
  app-screenshots/part2-frontend-dashboard.png Dashboard (Part 2, cross-VPC data)
  app-screenshots/part3-alb-frontend.png      Express home via ALB (Part 3)
  app-screenshots/part3-alb-dashboard.png     Dashboard via ALB (Part 3)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 QUICK VERIFICATION TEST (you can run these yourself right now)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  curl http://34.225.219.173:5000/api/health                       -> {"status":"healthy"}
  curl http://100.63.34.214:3000/                                  -> HTML page (Express)
  curl http://employee-alb-1009930769.us-east-1.elb.amazonaws.com/api/health
                                                                   -> {"status":"healthy"}

Public IPs are elastic and were live at submission time. If an IP ever stops
responding it is only because the resources were destroyed to stop AWS billing
(terraform destroy is documented in terraform/README.md -> Cleanup).