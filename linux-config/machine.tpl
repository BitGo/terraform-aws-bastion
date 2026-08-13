{
   "ignition":{
      "config":{},
      "timeouts":{},
      "version":"2.1.0"
   },
   "networkd":{},
   "passwd":{
      "users":[
         {
            "homeDir":"/dev/shm",
            "name":"tunnel",
            "noCreateHome":true,
            "shell":"/bin/false"
         }
      ]
   },
   "storage":{
      "files":[
         {
            "filesystem":"root",
            "group":{},
            "path":"/etc/ssh/sshd_config",
            "user":{},
            "contents":{
            "source": "data:text/plain;charset=utf-8;base64,${base64encode(
               <<-EOT
                 AllowUsers ${join(" ", allowed_users)}
                 AuthenticationMethods publickey
                 AuthorizedKeysCommandUser nobody
                 AuthorizedKeysCommand /etc/ssh/authorized_keys.sh
                 PermitRootLogin no
                 PermitTunnel yes
                 StreamLocalBindUnlink yes
                 KexAlgorithms -diffie-hellman-group1-sha1,-diffie-hellman-group14-sha1,-diffie-hellman-group14-sha256,-diffie-hellman-group16-sha512,-diffie-hellman-group18-sha512,-diffie-hellman-group-exchange-sha256
               EOT
               )}",
             "verification":{}
            }
         },
         {
            "filesystem":"root",
            "group":{},
            "path":"/etc/ssh/authorized_keys.sh",
            "user":{},
            "contents":{
               "source":"data:text/plain;charset=utf-8;base64,${base64encode(
               <<-EOT
                 #!/bin/bash
                 set -euo pipefail
                 TOKEN=$(curl -sf -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
                 ROLE=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
                 CREDS=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE")
                 AWS_ACCESS_KEY_ID=$(printf '%s' "$CREDS" | grep -o '"AccessKeyId" *: *"[^"]*"' | cut -d'"' -f4)
                 AWS_SECRET_ACCESS_KEY=$(printf '%s' "$CREDS" | grep -o '"SecretAccessKey" *: *"[^"]*"' | cut -d'"' -f4)
                 AWS_SESSION_TOKEN=$(printf '%s' "$CREDS" | grep -o '"Token" *: *"[^"]*"' | cut -d'"' -f4)
                 curl -sf --aws-sigv4 "aws:amz:${aws_region}:s3" \
                   --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
                   -H "x-amz-security-token: $AWS_SESSION_TOKEN" \
                   "https://${aws_s3_bucket}.s3.${aws_region}.amazonaws.com/${aws_s3_key}"
               EOT
               )}",
               "verification":{}
            },
            "mode":493
         }
      ]
   },
   "systemd":{
      "units":[
         {
            "dropins":[
               {
                  "contents":"[Socket]\nListenStream=\nListenStream=${ssh_port}\n",
                  "name":"10-sshd-port.conf"
               }
            ],
            "enabled":true,
            "name":"sshd.socket"
         },
         {
            "enabled":true,
            "mask":true,
            "name":"containerd.service"
         },
         {
            "enabled":true,
            "mask":true,
            "name":"docker.service"
         }
      ]
   }
 }
