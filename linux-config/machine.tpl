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
                 curl -sf ${aws_s3_bucket}/authorized_keys
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
