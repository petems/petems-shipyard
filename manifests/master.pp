# == Class shipyard::master
#
# This class is called to setup a Shipyard master
#
class shipyard::master (
  $shipyard_master_port = '8080',
  $docker_version = 'present',
){

  class {'::docker':
    version => $docker_version,
  }

  docker::run { 'shipyard-discovery':
    image            => 'microbox/etcd',
    command          => 'etcd -name discovery',
    ports            => [
      '4001:4001',
      '7001:7001',
    ],
    restart          => 'always',
    extra_parameters => [
      '--interactive=true',
    ],
    tty              => true,
  }

  docker::run { 'shipyard-rethinkdb':
    image            => 'rethinkdb',
    restart          => 'always',
    extra_parameters => [
      '--interactive=true',
    ],
    tty              => true,
  }

  docker::run { 'shipyard-proxy':
    image            => 'shipyard/docker-proxy:latest',
    hostname         => $::hostname,
    command          => 'etcd -name discovery',
    ports            => [
      '2375:2375',
    ],
    volumes          => [
      '/var/run/docker.sock:/var/run/docker.sock',
    ],
    env              => ['PORT=2375'],
    restart          => 'always',
    extra_parameters => [
      '--interactive=true',
    ],
    tty              => true,
  }

  docker::run { 'shipyard-swarm-manager':
    image            => 'swarm:latest',
    command          => "manage --host tcp://0.0.0.0:3375 etcd://${::ipaddress}:4001",
    volumes          => [
      '/var/run/docker.sock:/var/run/docker.sock',
    ],
    restart          => 'always',
    extra_parameters => [
      '--interactive=true',
    ],
    tty              => true,
  }

  docker::run { 'shipyard-swarm-agent':
    image            => 'swarm:latest',
    command          => "join --addr ${::ipaddress}:2375 etcd://${::ipaddress}:4001",
    restart          => 'always',
    extra_parameters => [
      '--interactive=true',
    ],
    tty              => true,
  }

  docker::run { 'shipyard-controller':
    image            => 'shipyard/shipyard:latest',
    command          => 'server -d tcp://swarm:3375',
    restart          => 'always',
    extra_parameters => [
      '--interactive=true',
    ],
    tty              => true,
    ports            => [
      "${shipyard_master_port}:8080",
    ],
    links            => [
      'shipyard-rethinkdb:rethinkdb',
      'shipyard-swarm-manager:swarm',
    ],
  }

}
