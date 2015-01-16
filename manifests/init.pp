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

  $mysql_root_password = '',
  $mysql_host = 'localhost',
  $mysql_bind_address = '127.0.0.1',
  $zanata_db_name = 'zanata',
  $zanata_db_username = 'zanata',
  $zanata_db_password = '',

  $zanata_wildfly_version = '8.1.0',
  $zanata_wildfly_install_url = 'http://download.jboss.org/wildfly/8.1.0.Final/wildfly-8.1.0.Final.tar.gz',

  $zanata_hibernate_url = 'http://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-hibernate-main-4.2.15.Final.zip',
  $zanata_mojarra_url = 'http://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-mojarra-2.1.28.zip',
  $zanata_url = 'https://sourceforge.net/projects/zanata/files/webapp/zanata-war-3.5.1.war',

) {

  $zanata_file = inline_template('<%= File.basename(@zanata_url) %>')
  $zanata_hibernate_file = inline_template('<%= File.basename(@zanata_hibernate_url) %>')
  $zanata_mojarra_file = inline_template('<%= File.basename(@zanata_mojarra_url) %>')

  class { 'zanata::mysql':
    mysql_root_password => $mysql_root_password,
    mysql_host          => $mysql_host,
    mysql_bind_address  => $mysql_bind_address,
    db_name             => $zanata_db_name,
    db_username         => $zanata_db_username,
    db_password         => $zanata_db_password,
  }

  require zanata::mysql

  class { 'zanata::wildfly':
    wildfly_version        => $zanata_wildfly_version,
    wildfly_install_source => $zanata_wildfly_install_url,
  }

  require zanata::wildfly

  package { [
    'libmysql-java',
    'unzip'
    ]:
    ensure => present,
  }

  file { '/home/wildfly/zanata':
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
    ensure => 'link',
    target => '/usr/share/java/mysql-connector-java.jar',
  }

  file { '/opt/wildfly/standalone/configuration/standalone.xml':
    ensure  => present,
    notify  => Service['wildfly'],
    owner   => wildfly,
    group   => wildfly,
    content => template('zanata/standalone.xml.erb'),
    require => [
                File['/opt/wildfly/standalone/deployments/ROOT.war'],
                Exec['unzip_mojarra'],
                Exec['unzip_hibernate'],
                ],
  }

}
