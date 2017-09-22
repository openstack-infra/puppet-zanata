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
  $zanata_main_version = 3,
  $zanata_db_name = 'zanata',
  $zanata_db_username = 'zanata',

  $zanata_wildfly_version = '10.1.0',
  $zanata_wildfly_install_url = 'https://repo1.maven.org/maven2/org/wildfly/wildfly-dist/10.1.0.Final/wildfly-dist-10.1.0.Final.tar.gz',

  $zanata_url = 'https://github.com/zanata/zanata-server/releases/download/server-3.9.6/zanata-3.9.6-wildfly.zip',
  # newer repo,e.g. https://github.com/zanata/zanata-platform/releases/download/platform-4.2.1/zanata-4.2.1-wildfly.zip
  # This should be a sha1 of whatever file is hosted at the url above.
  $zanata_checksum = 'cb7a477f46a118a337b59b9f4004ef7e6c77a1a8',

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

  package { 'unzip':
    ensure => present,
  }
  include '::archive'

  if ($zanata_ext == '.zip') {
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
    fail('zanata_url must be for a .zip file.')
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
