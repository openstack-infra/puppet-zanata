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
  $zanata_file = 'zanata-war-3.5.1.war',
) {
  package { [
    'libmysql-java',
    'unzip'
    ]:
    ensure => present,
  }
  exec { 'download_zanata':
    command => "/usr/bin/wget ${zanata_download}",
    cwd     => '/opt/wildfly/standalone/deployments/',
    creates => "${cwd}/${zanata_file}",
    user    => 'wildfly',
    require => [
      Package['wget'],
      User['wildfly']
    ]
  }
  exec { 'download_hibernate':
    command => "/usr/bin/wget ${zanata_hibernate}",
    cwd     => '/home/wildfly',
    user    => 'wildfly',
    require => [
      Package['wget'],
      User['wildfly']
    ]
  }
  exec { 'unzip_hibernate':
    command => "/usr/bin/unzip -o ${zanata_hibernate_file} -d /opt/wildfly/",
    cwd     => '/home/wildfly',
    user    => 'wildfly',
    require => [
      Package['unzip'],
      User['wildfly'],
      File['/opt/wildfly']
    ]
  }
  exec { 'download_mojarra':
    command => "/usr/bin/wget ${zanata_mojarra}",
    cwd     => '/home/wildfly',
    user    => 'wildfly',
    require => [
      Package['wget'],
      User['wildfly']
    ]
  }
  exec { 'unzip_mojarra':
    command => "/usr/bin/unzip -o ${zanata_mojarra_file} -d /opt/wildfly/",
    cwd     => '/home/wildfly',
    user    => 'wildfly',
    require => [
      Package['unzip'],
      User['wildfly'],
      File['/opt/wildfly']
    ]
  }
  exec { 'link_java':
    command => '/bin/ln -s /usr/share/java/mysql-connector-java.jar /opt/wildfly/standalone/deployments/',
    user    => 'root',
    require => File['/opt/wildfly'],
  }
}
