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
  $zanata_hibernate = 'http://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-hibernate-main-4.2.15.Final.zip',
  $zanata_hibernate_file = 'wildfly-8.1.0.Final-module-hibernate-main-4.2.15.Final.zip',
  $zanata_mojarra = 'http://sourceforge.net/projects/zanata/files/wildfly/wildfly-8.1.0.Final-module-mojarra-2.1.28.zip',
  $zanata_mojarra_file = 'wildfly-8.1.0.Final-module-mojarra-2.1.28.zip',
  $zanata_download = 'https://sourceforge.net/projects/zanata/files/webapp/zanata-war-3.5.1.war',
  $zanata_download_file = 'zanata-war-3.5.1.war',
  $zanata_tmp = '/tmp/zanata',
  $zanata_config_download = 'https://raw.githubusercontent.com/zanata/zanata-wildfly/master/standalone/configuration/standalone.xml',
) {

  require zanata::wildfly
  package { [
    'libmysql-java',
    'unzip'
    ]:
    ensure => present,
  }

  file { "/home/wildfly/zanata":
    ensure => "directory",
    owner => "wildfly",
    group => "wildfly"
  }
  file { '/tmp/zanata':
    ensure => "directory",
    owner => "wildfly",
  }
  exec { 'download_zanata':
    command => "/usr/bin/wget ${zanata_download}",
    cwd     => '/tmp/zanata',
    creates => '/tmp/zanata/${zanata_download_file}',
    user    => 'wildfly',
    timeout => 600,
    require => [
      File['/tmp/zanata'],
      Package['wget'],
    ]
  }
  exec { 'move_zanata':
    command => "/bin/mv ${zanata_tmp}/${zanata_download_file} /opt/wildfly/standalone/deployments/ROOT.war",
    cwd => '/tmp/zanata',
    creates => '/opt/wildfly/standalone/deployments/ROOT.war',
    user => 'wildfly',
    require => [
      Exec['download_zanata'],
    ]
  }

  exec { 'download_hibernate':
    command => "/usr/bin/wget ${zanata_hibernate}",
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
    command => "/usr/bin/wget ${zanata_mojarra}",
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

  exec { 'download_zanata_config':
    command => "/usr/bin/wget ${zanata_config_download}",
    creates => '/home/wildfly/standalone.xml',
    cwd => '/home/wildfly/',
    user => 'wildfly',
    require => [
      Package['wget'],
    ]
  }

  file { '/opt/wildfly/standalone/configuration/standalone.xml':
    notify => Service["wildfly"],
    source => '/home/wildfly/standalone.xml',
    owner => 'wildfly',
    require => [
      Exec['move_zanata'],
      Exec['download_zanata_config'],
    ]
  }

}
