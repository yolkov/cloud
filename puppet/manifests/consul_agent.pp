# == Class: tarantool_cloud::consul::agent
#
# Sets up an agent instance of Consul. The agent actively participates only
# in gossip traffic exchange. It can't be chosen as leader and doesn't
# participate in voting.
#
class tarantool_cloud::consul_agent{
  $config = {
    'data_dir'               => $tarantool_cloud::consul_data_dir,
    'bind_addr'              => '0.0.0.0',
    'client_addr'            => '0.0.0.0',
    'advertise_addr'         => $tarantool_cloud::advertise_addr,
    'ui'                     => true,
    'datacenter'             => $tarantool_cloud::datacenter,
    'log_level'              => 'INFO',
    'retry_join'             => [$tarantool_cloud::bootstrap_address],
    'ca_file'                => "${tarantool_cloud::tls_dir}/ca.pem",
    'cert_file'              => "${tarantool_cloud::tls_dir}/server_cert.pem",
    'key_file'               => "${tarantool_cloud::tls_dir}/server_key.pem",
    'verify_incoming'        => true,
    'verify_outgoing'        => true,
    'verify_server_hostname' => false,
    'encrypt'                => $tarantool_cloud::gossip_key,
    'acl_datacenter'         => $tarantool_cloud::datacenter,
    'acl_master_token'       => $tarantool_cloud::acl_master_token,
    'acl_token'              => 'anonymous',
    'acl_default_policy'     => 'deny',
    'server'                 => false
  }

  package { 'unzip':
    ensure => installed,
    name   => 'unzip',
  }

  file { '/etc/systemd/system/consul.service.d':
    ensure => directory
  }
  file { '/etc/systemd/system/consul.service.d/consul-docker.conf':
    content => '[Service]
    EnvironmentFile=-/etc/default/consul_docker'
  }

  file {'/etc/default/consul_docker':
    content => "DOCKER_HOST=${tarantool_cloud::advertise_addr}:2376
DOCKER_TLS_VERIFY=1
DOCKER_CERT_PATH=${tarantool_cloud::tls_dir}"
  }

  class { '::consul':
    config_hash => $config
  }

  ::consul::service { 'docker':
    checks => [
      {
      script   => "docker -H ${tarantool_cloud::advertise_addr}:2376 --tlsverify info",
      interval => '10s'
      }
    ],
    port   => 2376,
    tags   => ['im'],
    token  => $tarantool_cloud::acl_token
  }
}
