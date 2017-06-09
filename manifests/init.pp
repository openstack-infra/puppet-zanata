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
  $zanata_default_from_address,
  $zanata_db_password,
  $mysql_host = 'localhost',
  $mysql_port = '3306',
  $zanata_db_name = 'zanata',
  $zanata_db_username = 'zanata',

  # For wildfly < 10 the zanata_url below is expected to be a url to a built
  # war for wildfly >=10 the expectation is that it is the url to one of the
  # published zipfiles that can be overlaid atop the wildfly installation
  # dir.
  $zanata_wildfly_version = '9.0.1',
  $zanata_wildfly_install_url = 'https://repo1.maven.org/maven2/org/wildfly/wildfly-dist/9.0.1.Final/wildfly-dist-9.0.1.Final.tar.gz',

  $zanata_hibernate_url = 'https://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-hibernate-main-4.2.15.Final.zip',
  $zanata_mojarra_url = 'https://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-mojarra-2.1.28.zip',
  # The default here is to a war file and can be used with wildfly < 10.
  # If using wildfly >= 10 an example url would be:
  # https://github.com/zanata/zanata-server/releases/download/server-3.9.6/zanata-3.9.6-wildfly.zip
  $zanata_url = 'https://sourceforge.net/projects/zanata/files/webapp/zanata-war-3.7.3.war',
  # This should be a sha1 of whatever file is hosted at the url above.
  $zanata_checksum = '59f1ac35cce46ba4e46b06a239cd7ab4e10b5528',

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
  $zanata_hibernate_file = inline_template('<%= File.basename(@zanata_hibernate_url) %>')
  $zanata_mojarra_file = inline_template('<%= File.basename(@zanata_mojarra_url) %>')

  class { '::zanata::wildfly':
    wildfly_version        => $zanata_wildfly_version,
    wildfly_install_source => $zanata_wildfly_install_url,
  }

  file { $zanata_storage_dir:
    ensure => 'directory',
    owner  => 'wildfly',
    group  => 'wildfly'
  }

  package { 'unzip':
    ensure => present,
  }
  include '::archive'

  if ($zanata_ext == '.war') {
    # This implies the old wildfly <10 install method of installing wildfly
    # then manually injecting deps and the war into the wildfly install.
    # You need to make sure you provide a .war file url for zanata when
    # using wildfly < 10.
    package { 'libmysql-java':
      ensure => present,
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
  }
  elsif ($zanata_ext == '.zip') {
    # This implies the newer wildfly >= 10 install method where we install
    # wildfly, then unpack the zanata zip file into that install dir which
    # gives us all of our deps. You need to make sure you provide a .zip file
    # url for zanata when using wildfly >= 10.
    archive { "/tmp/${zanata_file}":
      ensure        => present,
      user          => 'wildfly',
      source        => $zanata_url,
      extract       => true,
      extract_path  => '/opt/wildfly',
      checksum_type => 'sha1',
      checksum      => $zanata_checksum,
      require       => [
        Class['wildfly::install'],
      ]
    }

    file { '/opt/wildfly/standalone/deployments/zanata.war.skipdeploy':
      # we don't want to serve at /zanata we want to serve at / so we skip
      # deploying with zanata.war and set up ROOT.war below.
      ensure  => present,
      require => Archive["/tmp/${zanata_file}"],
    }

    file { '/opt/wildfly/standalone/deployments/ROOT.war':
      ensure  => link,
      target  => '/opt/wildfly/standalone/deployments/zanata.war',
      require => Archive["/tmp/${zanata_file}"],
    }

    # TODO make this handle wildfly >= 10.
    file { '/opt/wildfly/standalone/configuration/standalone.xml':
      ensure  => present,
      notify  => Service['wildfly'],
      owner   => wildfly,
      group   => wildfly,
      content => template('zanata/wildfly-10-standalone.xml.erb'),
      require => [
                  Class['zanata::wildfly'],
                  File['/opt/wildfly/standalone/deployments/zanata.war.skipdeploy'],
                  File['/opt/wildfly/standalone/deployments/ROOT.war'],
                  ],
    }
  }
  else {
    fail('zanata_url must be for a .war or .zip file.')
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
