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
  $zanata_wildfly_install_url = 'https://download.jboss.org/wildfly/8.1.0.Final/wildfly-8.1.0.Final.tar.gz',

  $zanata_hibernate_url = 'https://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-hibernate-main-4.2.15.Final.zip',
  $zanata_mojarra_url = 'https://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-mojarra-2.1.28.zip',
  $zanata_url = 'https://sourceforge.net/projects/zanata/files/webapp/zanata-war-3.5.1.war',

  $zanata_default_from_address = '',
  $zanata_storage_dir = '/home/wildfly/zanata',

  $zanata_vhost_name = 'zanata.openstack.org',
  $zanata_serveradmin = "webmaster@${::fqdn}",
  $zanata_ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $zanata_ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $zanata_ssl_chain_file = '',
  $zanata_ssl_cert_file_contents = '',
  $zanata_ssl_key_file_contents = '',
  $zanata_ssl_chain_file_contents = '',

) {

  $zanata_file = inline_template('<%= File.basename(@zanata_url) %>')
  $zanata_hibernate_file = inline_template('<%= File.basename(@zanata_hibernate_url) %>')
  $zanata_mojarra_file = inline_template('<%= File.basename(@zanata_mojarra_url) %>')

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
    ]
  }

  exec { 'unzip_hibernate':
    command => "/usr/bin/unzip -o ${zanata_hibernate_file} -d /opt/wildfly/",
    cwd     => '/home/wildfly',
    user    => 'wildfly',
    require => [
      Exec['download_hibernate'],
      Package['unzip'],
    ]
  }

  exec { 'download_mojarra':
    command => "/usr/bin/wget ${zanata_mojarra_url}",
    cwd     => '/home/wildfly',
    creates => "/home/wildfly/${zanata_mojarra_file}",
    user    => 'wildfly',
    timeout => 600,
    require => [
      Package['wget'],
    ]
  }

  exec { 'unzip_mojarra':
    command => "/usr/bin/unzip -o ${zanata_mojarra_file} -d /opt/wildfly/",
    cwd     => '/home/wildfly',
    user    => 'wildfly',
    require => [
      Exec['download_mojarra'],
      Package['unzip'],
    ]
  }

  file { '/opt/wildfly/standalone/deployments/mysql-connector-java.jar':
    ensure  => 'link',
    target  => '/usr/share/java/mysql-connector-java.jar',
    require => [
                Package['libmysql-java'],
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
                Mysql::Db[$zanata_db_name],
                File['/opt/wildfly/standalone/deployments/ROOT.war'],
                Exec['unzip_mojarra'],
                Exec['unzip_hibernate'],
                ],
  }

  class { 'zanata::apache':
    vhost_name              => $zanata_vhost_name,
    serveradmin             => $zanata_serveradmin,
    ssl_cert_file           => $zanata_ssl_cert_file,
    ssl_key_file            => $zanata_ssl_key_file,
    ssl_chain_file          => $zanata_ssl_chain_file,
    ssl_cert_file_contents  => $zanata_ssl_cert_file_contents,
    ssl_key_file_contents   => $zanata_ssl_key_file_contents,
    ssl_chain_file_contents => $zanata_ssl_chain_file_contents,
    require                 => [
                                File['/opt/wildfly/standalone/configuration/standalone.xml'],
                                ],
  }
}
