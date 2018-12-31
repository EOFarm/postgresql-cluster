# README - pgpool

See also: [PgPool wiki](http://www.pgpool.net/mediawiki/index.php/Main_Page)

## 1. Check status

Check pool status by issuing pseudo-SQL `SHOW` commands to the PgPool frontend. For example:

    psql -U pgpool -h pgpool.internal -p 5433 -c 'SHOW pool_nodes' postgres

See also: http://www.pgpool.net/docs/latest/en/html/sql-commands.html

## 2. Perform a clean restart of PgPool

PgPool stores information about backend servers in status file `pgpool_status` inside (strangely named) `logdir` directory (usually `/var/run/postgresql`). 
This status file persists between restarts and if a backend server is marked as `down` it will stay as such (a server can move from `down` to `up` 
only by manual intervention).

So, if we want a clean restart (all backend servers will be polled again), we must remove the status file:

    systemctl stop pgpool2.service
    rm /var/run/postgresql/pgpool_status
    systemctl start pgpool2.service

## 3. Test load balancing

Use `pgbench` tool to send readonly or read/write workloads to server. 

First, create a testing database (directly on primary database):

    # we are on primary database
    sudo -u postgres createdb -O tester test_1

Initialize testing database (from anywhere):

     pgbench -U tester -h pgpool.internal -p 5433 -i test_1

Send a SELECT-only (flag `-S`) load to server. Retreive statistics with `SHOW pool_nodes` and verify that number of SELECT queries is fairly distributed to backend servers:

    pgbench -U tester -h pgpool.internal -p 5433 -c 10 -S -T 10 test_1 

Send a read/write transaction workload. Tail logs of backend servers and verify that only primary is receiving those transactions.

    pgbench -U tester -h pgpool.internal -p 5433 -c 10 -T 10 test_1 

## 4. Provide credentials for frontend database users

A database client has to authenticate against PgPool (the frontend) in a secure manner (here md5). Furthermore, PgPool has to maintain a pool of connections to backend servers (so it also has to authenticate against each one of them). Because of the way authentication is checked (a different salt is used from each backend, see [details](http://www.pgpool.net/mediawiki/index.php/FAQ#How_does_pgpool-II_handle_md5_authentication.3F)) PgPool has to maintain a store for user credentials (in addition to whatever store (table `pg_authid`) a PostgreSQL backend already maintains).

The store for these credentials is a plain file named `pool_passwd` and it has a quite simple format. For every user that we want to be able to connect to PgPool frontend the *same* credentials must exist in both PgPool side (i.e. inside `pool_passwd`) and in all PostgreSQL backend servers. Of course, the proper rules must also exist in `pool_hba.conf` to allow connecting to frontend, and in each `pg_hba.conf` to allow connecting to backend.

So, if we add a user in the primary backend (standy backend servers will replay this), we *must* also add this user in PgPool's credential store. A tool to assist in this task is `pg_md5`. For example, create the appropriate entry in `pool_passwd` for a user `tester`:

    pg_md5 --md5auth -p -f /etc/pgpool2/pgpool.conf -u tester

For other combinations of authentication methods between client/frontend/backend see [here](http://www.pgpool.net/mediawiki/index.php/FAQ#I_created_pool_hba.conf_and_pool_passwd_to_enable_md5_authentication_through_pgpool-II_but_it_does_not_work._Why.3F)

