# Copyright 2014 Hewlett-Packard Development Company, L.P.
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
class zanata::mysql(
  $mysql_root_password = '',
  $mysql_host = 'localhost',
  $mysql_bind_address = '127.0.0.1',
  $mysql_port = '3306',
  $db_name = 'zanata',
  $db_username = 'zanata',
  $db_password,

) {

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => $mysql_bind_address,
      'port'           => $mysql_port,
    }
  }

  include mysql::server::account_security

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
}
