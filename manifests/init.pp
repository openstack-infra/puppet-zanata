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
# Class to install Zanata

class zanata {
  package { 'openjdk-7-jre-headless':
    ensure => present,
  }
  class { 'wildfly::install':
    version        => '8.2.0',
    install_source => 'http://download.jboss.org/wildfly/8.2.0.Final/wildfly-8.2.0.Final.tar.gz',
    install_file   => 'wildfly-8.2.0.Final.tar.gz',
    java_home      => '/usr/lib/jvm/java-7-openjdk-amd64/jre/',
    require        => Package['openjdk-7-jre-headless'],
  }
}
