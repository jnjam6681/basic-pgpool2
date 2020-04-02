# PostgreSQL Server
## System Architecture
![](images/diagram.png)
---

## Requirement

Hostname     | IP Address
-------------|--------------
pgpool-1     | 192.168.33.11
postgresql-1 | 192.168.33.21  
postgresql-2 | 192.168.33.22

---

## Install PostgreSQL in primary and standby server
#### login root user
```
sudo su
```

#### update repository
```
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
```
```
wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
```

#### update packages
```
apt-get update
apt-get upgrade -y
```

#### install postgresql
```
apt-get install -y postgresql-12
```
---
## config in primary server
#### create user for replication in database (named replication and REPLICATION privileges)
```
su - postgres
psql
CREATE ROLE pgpool WITH REPLICATION PASSWORD '12345678' LOGIN;
CREATE ROLE admin WITH NOSUPERUSER CREATEDB PASSWORD '12345678' LOGIN;
\q
```

#### change config in postgresql.conf file
```
nano /etc/postgresql/12/main/postgresql.conf
```
```
listen_addresses = '*'
wal_level = hot_standby # send data without delay
max_replication_slots = 3 # set maximal number of replication slots
max_wal_senders = 3 # maximal number of concurrent connections from standby servers
hot_standby = on
synchronous_standby_names = '*'
```
or use shell scripts
```
sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
sed -i -e "s/#wal_level = replica/wal_level = hot_standby/g" /etc/postgresql/12/main/postgresql.conf
sed -i -e "s/#max_wal_senders = 10/max_wal_senders = 311/g" /etc/postgresql/12/main/postgresql.conf
sed -i -e "s/#max_replication_slots = 10/max_replication_slots = 3/g" /etc/postgresql/12/main/postgresql.conf
sed -i -e "s/#hot_standby = on/hot_standby = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i -e "s/#synchronous_standby_names = ''/synchronous_standby_names = '*'/g" /etc/postgresql/12/main/postgresql.conf
```

#### add/change in pg_hba.conf file
```
nano /etc/postgresql/12/main/pg_hba.conf
```
```
host    replication     all             192.168.33.21/32        trust # postgres-1
host    replication     all             192.168.33.22/32        trust # postgres-2
host    postgres        pgpool          192.168.33.11/32        trust # pgpool-1
host    all             all             192.168.33.11/32        md5 # pgpool-1
```

#### restart service postgresql in primary server
```
service postgresql restart
```

#### create replication slot in primary server
```
su - postgres
psql
SELECT * FROM pg_create_physical_replication_slot('it_rdbms02');
\q
```

#### restart service postgresql in primary server
```
service postgresql restart
```
---
## config in standby server
#### change config in postgresql.conf file agian
```
nano /etc/postgresql/12/main/postgresql.conf
```
```
listen_addresses = '*'
wal_level = hot_standby # send data without delay
hot_standby = on
hot_standby_feedback = on
```
or use shell scripts
```
sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
sed -i -e "s/#wal_level = replica/wal_level = hot_standby/g" /etc/postgresql/12/main/postgresql.conf
sed -i -e "s/#hot_standby = on/hot_standby = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i -e "s/#hot_standby_feedback = off/hot_standby_feedback = on/g" /etc/postgresql/12/main/postgresql.conf
```

#### add/change in pg_hba.conf file
```
nano /etc/postgresql/12/main/pg_hba.conf
```
```
host    postgres        pgpool          192.168.33.11/32        trust # pgpool-1
host    all             all             192.168.33.11/32        md5 # pgpool-1
```

#### stop postgresql in standby server and remove the data directory
```
service postgresql stop
cd /var/lib/postgresql/12
rm -rf main
```

#### execute pg_basebackup command in order to get initial state from primary server
```
su - postgres
pg_basebackup -v -D /var/lib/postgresql/12/main -R -P -h 192.168.33.21 -p 5432
```
---
## testing replication
#### primary server
```
systemctl status postgresql
sudo -u postgres psql
CREATE DATABASE replicationtest;
CREATE DATABASE
\l
```

#### standy server
```
systemctl status postgresql
sudo -u postgres psql
\l
```

#### if you can't use psql in standby server
```
chown -R postgres:postgres /var/lib/postgresql/12/
chmod -R u=rwX,go= /var/lib/postgresql/12/
systemctl restart postgresql
```

---

## pgpool2 server
#### login root user
```
sudo su
```
#### update repository
```
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
```
```
wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
```

#### update packages
```
apt-get update
apt-get upgrade -y
```

#### install packages
```
apt-get install -y postgresql-client-12 pgpool2
```

#### update config pgpool
```
nano /etc/pgpool2/pgpool.conf
```
```
listen_addresses = '*'   

backend_hostname0 = '192.168.33.21'
backend_port0 = 5432
backend_weight0 = 1
backend_data_directory0 = '/var/lib/postgresql/12/main'

listen_addresses = '*'            
backend_hostname0 = '192.168.33.22'
backend_port0 = 5432
backend_weight0 = 1
backend_data_directory0 = '/var/lib/postgresql/12/main'

enable_pool_hba = on
pool_passwd = 'pool_passwd'

load_balance_mode = on

master_slave_mode = on
master_slave_sub_mode = 'stream'

sr_check_user = 'pgpool'
wd_lifecheck_user = 'pgpool'
```

#### update pool_hba.conf
```
nano /etc/pgpool2/pool_hba.conf
```
```
host    replication     all             192.168.33.21/32        trust
host    replication     all             192.168.33.22/32        trust
host    postgres        pgpool          192.168.33.11/32        trust
host    all             all             192.168.33.11/32        md5
```

#### stop and start pgpool
```
pgpool stop
```
```
pgpool -n
pgpool  
```

#### testing pgpool
```
createdb -h 192.168.33.11 db-admin -U admin
psql -h 192.168.33.11 db-admin -U admin
```
---
```
Success. You can now start the database server using:

    pg_ctlcluster 12 main start

Ver Cluster Port Status Owner    Data directory              Log file
12  main    5432 down   postgres /var/lib/postgresql/12/main /var/log/postgresql/postgresql-12-main.log
```
