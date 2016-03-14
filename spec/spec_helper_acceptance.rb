require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    shell("/bin/yum update lvm2 -y")
    shell("/bin/rm -rf /shipyard")
    shell("/bin/rm -rf /etc/puppet/modules/shipyard")
    puppet_module_install(:source => proj_root, :module_name => 'shipyard')
    shell("/bin/mv /shipyard /etc/puppet/modules/shipyard")
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0] }
      on host, puppet('module', 'install', 'garethr-docker'), { :acceptable_exit_codes => [0] }
    end
  end
end
