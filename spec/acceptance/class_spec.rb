require 'spec_helper_acceptance'

describe 'shipyard class' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      class { '::shipyard::master': }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    shipyard_containers = [
      'shipyard-discovery',
      'shipyard-rethinkdb',
      'shipyard-proxy',
      'shipyard-swarm-manager',
      'shipyard-swarm-agent',
      'shipyard-controller',
      'shipyard-discovery',
      'shipyard-rethinkdb',
      'shipyard-proxy',
      'shipyard-swarm-manager',
      'shipyard-swarm-agent',
      'shipyard-controller',
    ]

    shipyard_images = [
      'microbox/etcd',
      'rethinkdb',
      'shipyard/docker-proxy:latest',
      'swarm:latest',
      'swarm:latest',
      'shipyard/shipyard:latest',
    ]

    shipyard_containers.each do | shipyard_container |
      describe docker_container(shipyard_container) do
        it { should be_running }
      end
    end

    shipyard_images.each do | shipyard_image |
      describe docker_image(shipyard_image) do
        it { should exist }
      end
    end

    context 'Shipyard should be running on the default port' do
      describe command('sleep 5 && echo "Give Shipyard time to start"') do
        its(:exit_status) { should eq 0 }
      end

      describe command('curl 0.0.0.0:8080/') do
        its(:stdout) { should match /\<title>shipyard<\/title>/ }
      end
    end

  end
end
