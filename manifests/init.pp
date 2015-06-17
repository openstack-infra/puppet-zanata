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
# == Class: zanata
#

class zanata(
  $mysql_host = 'localhost',
  $mysql_port = '3306',
  $zanata_db_name = 'zanata',
  $zanata_db_username = 'zanata',
  $zanata_db_password,

  $zanata_wildfly_version = '8.1.0',
  $zanata_wildfly_install_url = 'https://repo1.maven.org/maven2/org/wildfly/wildfly-dist/8.1.0.Final/wildfly-dist-8.1.0.Final.tar.gz',

  $zanata_hibernate_url = 'https://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-hibernate-main-4.2.15.Final.zip',
  $zanata_mojarra_url = 'https://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-mojarra-2.1.28.zip',
  $zanata_url = 'https://sourceforge.net/projects/zanata/files/webapp/zanata-war-3.6.2.war',

  $zanata_default_from_address,
  $zanata_storage_dir = '/home/wildfly/zanata',

  $zanata_openid_provider_url = '',
  $zanata_admin_users = '',

  $zanata_listeners = [],

  $zanata_smtp_host = '',
  $zanata_smtp_port = '',
  $zanata_smtp_username = '',
  $zanata_smtp_password = '',
  $zanata_smtp_tls = '',
  $zanata_smtp_ssl = '',

) {

  $zanata_file = inline_template('<%= File.basename(@zanata_url) %>')
  $zanata_hibernate_file = inline_template('<%= File.basename(@zanata_hibernate_url) %>')
  $zanata_mojarra_file = inline_template('<%= File.basename(@zanata_mojarra_url) %>')

  zanata::validate_listener { $zanata_listeners:
  }

  class { 'zanata::wildfly':
    wildfly_version        => $zanata_wildfly_version,
    wildfly_install_source => $zanata_wildfly_install_url,
  }

  package { [
    'libmysql-java',
    'unzip'
    ]:
    ensure => present,
  }

  file { $zanata_storage_dir:
    ensure => 'directory',
    owner  => 'wildfly',
    group  => 'wildfly'
  }

  exec { 'download_zanata':
    command => "/usr/bin/wget ${zanata_url}",
    cwd     => '/home/wildfly',
    creates => "/home/wildfly/${zanata_file}",
    user    => 'wildfly',
    timeout => 600,
    require => [
      Package['wget'],
    ]
  }

  file { '/opt/wildfly/standalone/deployments/ROOT.war':
    ensure  => present,
    source  => "/home/wildfly/${zanata_file}",
    owner   => 'wildfly',
    require => [
      Exec['download_zanata'],
    ]
  }

  exec { 'download_hibernate':
    command => "/usr/bin/wget ${zanata_hibernate_url}",
    cwd     => '/home/wildfly',
    creates => "/home/wildfly/${zanata_hibernate_file}",
    user    => 'wildfly',
    timeout => 600,
    require => [
      Package['wget'],
    notify  => Exec['unzip_hibernate'],
    ]
  }

  exec { 'unzip_hibernate':
    command => "/usr/bin/unzip -o ${zanata_hibernate_file} -d /opt/wildfly/",
    cwd     => '/home/wildfly',
    user    => 'wildfly',
    require => [
      Package['unzip'],
      File["/home/wildfly/${zanata_hibernate_file}"],
    ]
    refreshonly => true,
  }

  exec { 'download_mojarra':
    command => "/usr/bin/wget ${zanata_mojarra_url}",
    cwd     => '/home/wildfly',
    creates => "/home/wildfly/${zanata_mojarra_file}",
    user    => 'wildfly',
    timeout => 600,
    require => [
      Package['wget'],
    notify  => Exec['unzip_mojarra'],
    ]
  }

  exec { 'unzip_mojarra':
    command => "/usr/bin/unzip -o ${zanata_mojarra_file} -d /opt/wildfly/",
    cwd     => '/home/wildfly',
    user    => 'wildfly',
    require => [
      Package['unzip'],
      File["/home/wildfly/${zanata_mojarra_file}"],
    ]
    refreshonly => true,
  }

  file { '/opt/wildfly/standalone/deployments/mysql-connector-java.jar':
    ensure  => 'link',
    target  => '/usr/share/java/mysql-connector-java.jar',
    require => [
                Package['libmysql-java'],
                Class['zanata::wildfly'],
                ],
  }

  file { '/opt/wildfly/standalone/configuration/standalone.xml':
    ensure  => present,
    notify  => Service['wildfly'],
    owner   => wildfly,
    group   => wildfly,
    content => template('zanata/standalone.xml.erb'),
    require => [
                Class['zanata::wildfly'],
                File['/opt/wildfly/standalone/deployments/ROOT.war'],
                Exec['unzip_mojarra'],
                Exec['unzip_hibernate'],
                ],
  }
}

# == Define: zanata::validate_listener
#
define zanata::validate_listener ($listener = $name) {
  $listeners = [ 'https', 'ajp' ]
  if $listener and !($listener in $listeners) {
    fail("${listener} is not a valid listener type")
  }
}
