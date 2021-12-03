Lambda function to clean up old AMIs that not are in use
# Usage
``` hcl
module "clean_old_ami" {
  source  = "pauloconnor/terraform-aws-ami-cleanup"
  prefix  = "ami-"
}
```
