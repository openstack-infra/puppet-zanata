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

  $zanata_wildfly_version = '9.0.1',
  $zanata_wildfly_install_url = 'https://repo1.maven.org/maven2/org/wildfly/wildfly-dist/9.0.1.Final/wildfly-dist-9.0.1.Final.tar.gz',

  $zanata_hibernate_url = 'https://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-hibernate-main-4.2.15.Final.zip',
  $zanata_mojarra_url = 'https://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-mojarra-2.1.28.zip',
  $zanata_url = 'https://sourceforge.net/projects/zanata/files/webapp/zanata-war-3.7.3.war',
  $zanata_checksum = '59f1ac35cce46ba4e46b06a239cd7ab4e10b5528',

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
  $wildfly_file = inline_template('<%= File.basename(@zanata_wildfly_install_url) %>')
  $zanata_hibernate_file = inline_template('<%= File.basename(@zanata_hibernate_url) %>')
  $zanata_mojarra_file = inline_template('<%= File.basename(@zanata_mojarra_url) %>')

  zanata::validate_listener { $zanata_listeners:
  }

  class { '::zanata::wildfly':
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

  include '::archive'

  archive { '/opt/wildfly/standalone/deployments/ROOT.war':
    ensure        => present,
    user          => 'wildfly',
    source        => $zanata_url,
    checksum_type => 'sha1',
    checksum      => $zanata_checksum,
    require       => [
      Class['wildfly::install'],
    ]
  }

  # The mysql driver name differs based on the version of the package. Ensure
  # we set it correctly when writing the standalone.xml config file below.
  if ($::operatingsystem == 'Ubuntu') and ($::operatingsystemrelease >= '16.04') {
    $mysql_driver_name = 'mysql-connector-java.jar_com.mysql.jdbc.Driver_5_1'
  }
  else {
    $mysql_driver_name = 'mysql-connector-java.jar'
  }

  file { '/opt/wildfly/standalone/deployments/mysql-connector-java.jar':
    ensure  => 'link',
    target  => '/usr/share/java/mysql-connector-java.jar',
    require => [
                Package['libmysql-java'],
                Class['zanata::wildfly'],
                ],
  }

  if ($zanata_wildfly_version < '10.0.0') {
    archive { "/home/wildfly/${zanata_hibernate_file}":
      ensure       => present,
      user         => 'wildfly',
      source       => $zanata_hibernate_url,
      extract      => true,
      extract_path => '/opt/wildfly/',
      require      => Package['unzip'],
    }

    archive { "/home/wildfly/${zanata_mojarra_file}":
      ensure       => present,
      user         => 'wildfly',
      source       => $zanata_mojarra_url,
      extract      => true,
      extract_path => '/opt/wildfly/',
      require      => Package['unzip'],
    }

    file { '/opt/wildfly/standalone/configuration/standalone.xml':
      ensure  => present,
      notify  => Service['wildfly'],
      owner   => wildfly,
      group   => wildfly,
      content => template('zanata/wildfly-9-standalone.xml.erb'),
      require => [
                  Class['zanata::wildfly'],
                  Archive['/opt/wildfly/standalone/deployments/ROOT.war'],
                  Archive["/home/wildfly/${zanata_mojarra_file}"],
                  Archive["/home/wildfly/${zanata_hibernate_file}"],
                  ],
    }
  } else {
    file { '/opt/wildfly/standalone/configuration/standalone.xml':
      ensure  => present,
      notify  => Service['wildfly'],
      owner   => wildfly,
      group   => wildfly,
      content => template('zanata/wildfly-10-standalone.xml.erb'),
      require => [
                  Class['zanata::wildfly'],
                  Archive['/opt/wildfly/standalone/deployments/ROOT.war'],
                  ],
    }
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
