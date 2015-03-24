# Copyright 2015 Hewlett-Packard Development Company, L.P.
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
# == Class: zanata::client
#
class zanata::client(
  $version = '3.4.2',
  $user = 'jenkins',
  $group = 'jenkins',
) {

  file { '/opt/zanata':
    ensure  => directory,
    owner   => "${user}",
    group   => "${group}",
    mode    => '0644',
    require => User["${user}"],
  }

  exec { 'get_zanata_client_dist_tarball':
    command => "wget https://search.maven.org/remotecontent?filepath=org/zanata/zanata-cli/${version}/zanata-cli-${version}-dist.tar.gz -O /opt/zanata/zanata-cli-${version}-dist.tar.gz",
    path    => '/bin:/usr/bin',
    creates => "/opt/zanata/zanata-cli-${version}-dist.tar.gz",
    require => File['/opt/zanata'],
  }

  file { "/opt/zanata/zanata-cli-${version}-dist.tar.gz":
    ensure  => present,
    owner   => "${user}",
    group   => "${group}",
    mode    => '0644',
    require => Exec['get_zanata_client_dist_tarball'],
  }

  exec { 'unpack_zanata_client_dist_tarball':
    command => "tar zxf zanata-cli-${version}-dist.tar.gz",
    path    => '/bin:/usr/bin',
    user    => "${user}",
    cwd     => '/opt/zanata',
    creates => "/opt/zanata/zanata-cli-${version}/bin/zanata-cli",
    require => Exec['get_zanata_client_dist_tarball'],
  }

  file { "/opt/zanata/zanata-cli-${version}/bin/zanata-cli":
    ensure  => present,
    owner   => "${user}",
    group   => "${group}",
    mode    => '0755',
    require => Exec['unpack_zanata_client_dist_tarball'],
  }

  file { '/usr/local/bin/zanata-cli':
    ensure  => link,
    target  => "/opt/zanata/zanata-cli-${version}/bin/zanata-cli",
    require => File["/opt/zanata/zanata-cli-${version}/bin/zanata-cli"],
  }

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }
}
