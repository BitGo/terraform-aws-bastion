# Terraform AWS Bastion #

<http://github.com/BitGo/terraform-aws-bastion>

## About ##

Deploy a minimal, auto-healing, and immutable SSH Bastion host on AWS.

SSH is configured to dynamically pull a list of authorized_keys from a public S3 bucket.

## Features ##

  * Automatically re-deploy via ASG and health checks
  * Automatic updates via CoreOS
  * Static IP via Network Load Balancer
  * Public keys fetched on the fly from s3 bucket

## Usage  ##

### Variables

  * ```name``` - name of the bastion; suggest 'bastion-<unique_identifier>'
  * ```instance_type``` - instance type of bastion
  * ```additional_security_groups``` - security groups to add to the bastion instance, e.g. if you have other security groups with "source_security_group" rules that you'd like the bastion to be covered by
  * ```authorized_keys_directory``` - folder of keys to allow for ssh
  * ```authorized_key_names``` - names of public keys to allow for ssh
  * ```allowed_cidrs``` - CIDRs that are allowed to reach instance via SSH
  * ```allowed_egress_cidrs``` - CIDRs that the bastion (and hence users of it) are allowed to reach
  * ```allowed_ipv6_egress_cidrs``` - IPv6 CIDRs that the bastion (and hence users of it) are allowed to reach
  * ```allowed_users``` - Allowed users to ssh. Defaults to shellless 'tunnel' user
  * ```create_egress_rule``` - Should a security group rule for egress be created? (in certain circumstances you may want to manage these externally using the `security_group` output)
  * ```vpc_id``` - ID of VPC to launch instances in
  * ```private_subnets``` - Where the EC2 and ASG things live
  * ```public_subnets``` - Where the ELB lives
  * ```ssh_port``` - Port for SSH to listen on
  * ```key_name``` - specify aws ssh key name to launch instance with
  * ```iam_instance_profile``` - specify an IAM instance profile
  * ```associate_public_ip_address``` - associate public ip address for EC2 instance

### Outputs

  * ```dns_name``` - DNS Name of the load balancer used to reach bastions
  * ```s3_bucket``` - The s3 bucket name that keys are stored in
  * ```security_group``` - The security group id created and assigned to the bastion host
  * ```zone_id``` - The ELB Zone Id assigned to the load balancer. Used by Route53 for alias records.

### Example

```bash
module "bastion" {
  source = "github.com/BitGo/terraform-aws-bastion"
  version = "0.0.1"
  name = "bastion-abc"
  instance_type = "t3.nano"
  authorized_keys_directory = "keys/ssh/"
  authorized_key_names = ["alice", "bob", "mallory"]
  allowed_cidrs = ["0.0.0.0/0"]
  vpc_id = "vpc-123456"
  ssh_port = 22
  public_subnets = ["subnet-6789123"]
  private_subnets = ["subnet-123456", "subnet-321321"]
}
```
