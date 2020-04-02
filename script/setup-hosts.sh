#!/bin/bash

cat >> /etc/hosts <<EOF
192.168.33.11  pgpool-1
192.168.33.21  postgresql-1
192.168.33.22  postgresql-2
EOF