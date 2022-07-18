// Tested in us-west-2
data "aws_ami" "flatcar" {
  most_recent = true
  owners      = ["075585003325"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "name"
    values = ["Flatcar-stable-*"]
  }
}

// Just in case something goes wrong, the AMI ID for us-west-2 flatcar is 'ami-0bb54692374ac10a7'
// Source: https://docs.flatcar-linux.org/os/booting-on-ec2/
//
resource "aws_launch_template" "bastion" {
  image_id      = data.aws_ami.flatcar.image_id
  instance_type = var.instance_type
  user_data = base64encode(jsonencode({
    ignition = {
      config   = {}
      timeouts = {}
      version  = "2.1.0"
    },
    networkd = {}
    passwd = {
      users = [
        {
          homeDir      = "/dev/shm"
          name         = "tunnel"
          noCreateHome = true,
          shell        = "/bin/false"
        }
      ]
    },
    storage = {
      files = [
        {
          filesystem = "root"
          group      = {}
          path       = "/etc/ssh/sshd_config"
          user       = {}
          contents = {
            source = "data:text/plain;charset=utf-8;base64,${base64encode(
              <<-EOT
                AllowUsers ${join(" ", var.allowed_users)}
                AuthenticationMethods publickey
                AuthorizedKeysCommandUser nobody
                AuthorizedKeysCommand /etc/ssh/authorized_keys.sh
                PermitRootLogin no
                PermitTunnel yes
                StreamLocalBindUnlink yes
              EOT
            )}"
            verification = {}
          }
        },
        {
          filesystem = "root"
          group      = {}
          path       = "/etc/ssh/authorized_keys.sh"
          user       = {}
          contents = {
            source = "data:text/plain;charset=utf-8;base64,${base64encode(
              <<-EOT
                #!/bin/bash
                curl -sf "${aws_s3_bucket.ssh_public_keys.website_endpoint}/authorized_keys"
              EOT
            )}"
            verification = {}
          },
          mode = 493
        }
      ]
    },
    systemd = {
      units = [
        {
          dropins = [
            {
              contents = <<-EOT
                [Socket]
                ListenStream=
                ListenStream=${var.ssh_port}
              EOT
              name     = "10-sshd-port.conf"
            }
          ],
          enabled = true
          name    = "sshd.socket"
        },
        {
          enabled = true
          mask    = true
          name    = "containerd.service"
        },
        {
          enabled = true,
          mask    = true,
          name    = "docker.service"
        }
      ]
    }
  }))
  key_name = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    security_groups = concat(
      [aws_security_group.bastion.id],
      var.additional_security_groups,
    )

    associate_public_ip_address = var.associate_public_ip_address
  }
}
