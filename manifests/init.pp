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
  $zanata_default_from_address,
  $zanata_db_password,
  $mysql_host = 'localhost',
  $mysql_port = '3306',
  $zanata_main_version = 3,
  $zanata_db_name = 'zanata',
  $zanata_db_username = 'zanata',

  $zanata_wildfly_version = '10.1.0',
  $zanata_wildfly_install_url = 'https://repo1.maven.org/maven2/org/wildfly/wildfly-dist/10.1.0.Final/wildfly-dist-10.1.0.Final.tar.gz',

  $zanata_url = 'https://github.com/zanata/zanata-server/releases/download/server-3.9.6/zanata-war-3.9.6.war',
  # newer repo,e.g. https://github.com/zanata/zanata-platform/releases/download/platform-4.3.3/zanata-war-4.3.3.war
  # This should be a sha1 of whatever file is hosted at the url above.
  $zanata_checksum = '67a360616eaf442b089a39921ff22149d2f0fdb5',

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
  zanata::validate_listener { $zanata_listeners: }

  $zanata_file = inline_template('<%= File.basename(@zanata_url) %>')
  $zanata_ext = inline_template('<%= File.extname(@zanata_url) %>')
  $wildfly_file = inline_template('<%= File.basename(@zanata_wildfly_install_url) %>')

  class { '::zanata::wildfly':
    wildfly_version        => $zanata_wildfly_version,
    wildfly_install_source => $zanata_wildfly_install_url,
  }

  file { $zanata_storage_dir:
    ensure => 'directory',
    owner  => 'wildfly',
    group  => 'wildfly'
  }

  package { 'libmysql-java':
    ensure => present,
  }

  include '::archive'

  if ($zanata_ext != '.war') {
    fail('zanata_url must be for a .war file.')
  }

# The mysql driver name differs based on the version of the package. Ensure
# we set it correctly when writing the standalone.xml config file below.
# Note that this isn't the name used by files on disk, rather it is some
# java class lookup name used in the standalone.xml configuration file.
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

# == Define: zanata::validate_listener
#
define zanata::validate_listener ($listener = $name) {
  $listeners = [ 'https', 'ajp' ]
  if $listener and !($listener in $listeners) {
    warn("${listener} is not a valid listener type")
  }
}
