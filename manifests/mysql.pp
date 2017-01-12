# Copyright 2014 Hewlett-Packard Development Company, L.P.
# Copyright 2017 Deutsche Telekom AG, Frank Kloeker <f.kloeker@telekom.de>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: zanata::mysql
#
# Maintaining MySQL backend for zanata (incl. backups)
#
# === Parameters
#
# [*mysql_root_password*]
# Root password for MySQL (default: root)
#
# [*mysql_host*]
# Hostname for MySQL backend (default: localhost)
#
# [*mysql_bind_address*]
# Bind address for MySQL service (default: 127.0.0.1)
#
# [*mysql_port*]
# Port auf MySQL service (default: 3306)
#
# [*db_name*]
# Name of MySQL database (default: zanata)
#
# [*db_username*]
# MySQL username for application (default: zanata)
#
# [*db_password*]
# MySQL password for application user
#
# [*mysqlbackup*]
# Trigger for doing backups? true or false
#
# [*backupuser*]
# MySQL username for backup (default: backup)
#
# [*backuppassword*]
# MySQL password for backup user
#
# [*backupdir*]
# Target directory for backup files (default: /data/mysql_backups)
#
# [*backuprotate*]
# Days of rotating backup files (default: 35)
#
# [*backupdbs*]
# Array of databases to backup (default: ['zanata']
#
# [*backuptime*]
# Array in ['hh','mm'] for backup cron (default: 23:05)
#
#
class zanata::mysql(
  $mysql_root_password = 'root',
  $mysql_host = 'localhost',
  $mysql_bind_address = '127.0.0.1',
  $mysql_port = '3306',
  $db_name = 'zanata',
  $db_username = 'zanata',
  $db_password,
  $mysqlbackup = undef,
  $backupuser,
  $backuppassword,
  $backupdir = '/data/mysql_backups',
  $backuprotate = '35',
  $backupdbs = ['zanata'],
  $backuptime = ['23','5'],
) {

  class { '::mysql::server':
    root_password    => $mysql_root_password,
    override_options => {
      'mysqld' => {
        'default-storage-engine' => 'InnoDB',
        'bind-address'           => $mysql_bind_address,
        'port'                   => $mysql_port,
      }
    },
  }

  include ::mysql::server::account_security

  mysql::db { $db_name:
    user     => $db_username,
    password => $db_password,
    host     => $mysql_host,
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
                  Class['mysql::server'],
                  Class['mysql::server::account_security'],
                ],
  }

  if $mysqlbackup == true {
    class { '::mysql::server::backup':
      ensure            => present,
      backupuser        => $backupuser,
      backuppassword    => $backuppassword,
      backupdir         => $backupdir,
      backupcompress    => true,
      backuprotate      => $backuprotate,
      backupdatabases   => $backupdbs,
      file_per_database => true,
      time              => $backuptime,
    }
  }
}
