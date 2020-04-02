#!/bin/bash

cat >> /etc/resolv.conf <<EOF
nameserver 8.8.8.8
EOF

# sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
# service systemd-resolved restart