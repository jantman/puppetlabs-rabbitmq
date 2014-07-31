require 'spec_helper_acceptance'

describe 'rabbitmq class:' do
  case fact('osfamily')
  when 'RedHat'
    package_name = 'rabbitmq-server'
    service_name = 'rabbitmq-server'
    package_source_281 = "http://www.rabbitmq.com/releases/rabbitmq-server/v2.8.1/rabbitmq-server-2.8.1-1.noarch.rpm"
    package_ensure_281 = '2.8.1-1'
  when 'SUSE'
    package_name       = 'rabbitmq-server'
    service_name       = 'rabbitmq-server'
    package_source_281 = "http://www.rabbitmq.com/releases/rabbitmq-server/v2.8.1/rabbitmq-server-2.8.1-1.noarch.rpm"
    package_ensure_281 = '2.8.1-1'
  when 'Debian'
    package_name       = 'rabbitmq-server'
    service_name       = 'rabbitmq-server'
    package_source_281 = ''
    package_ensure_281 = '2.8.1'
  when 'Archlinux'
    package_name       = 'rabbitmq'
    service_name       = 'rabbitmq'
    package_source_281 = ''
    package_ensure_281 = '2.8.1'
  end

  context "default class inclusion" do
    it 'should run successfully' do
      pp = <<-EOS
      class { 'rabbitmq': }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      # Apply twice to ensure no errors the second time.
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_changes => true).exit_code).to be_zero
    end

    describe package(package_name) do
      it { should be_installed }      
    end

    describe service(service_name) do
      it { should be_enabled }
      it { should be_running }
    end
  end

  context "disable and stop service" do
    it 'should run successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        service_ensure => 'stopped',
      }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
    end

    describe service(service_name) do
      it { should_not be_enabled }
      it { should_not be_running }
    end
  end

  context "service is unmanaged" do
    it 'should run successfully' do
      pp_pre = <<-EOS
      class { 'rabbitmq': }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      pp = <<-EOS
      class { 'rabbitmq':
        service_manage => false,
        service_ensure  => 'stopped',
      }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      
      apply_manifest(pp_pre, :catch_failures => true)
      apply_manifest(pp, :catch_failures => true)
    end

    describe service(service_name) do
      it { should be_enabled }
      it { should be_running }
    end
  end

  context "specified version 2.8.1-1" do
    it 'should run successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        version          => '2.8.1-1',
        package_source   => '#{package_source_281}',
        package_ensure   => '#{package_ensure_281}',
        package_provider => 'rpm',
      }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      # Apply twice to ensure no errors the second time.
      shell('yum -y erase rabbitmq-server')
      shell('rm -Rf /var/lib/rabbitmq/mnesia /etc/rabbitmq')
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_changes => true).exit_code).to be_zero
    end

    describe command('rabbitmqctl status') do
      its(:stdout) { should match /{rabbit,"RabbitMQ","2.8.1"}/ }
    end

    describe package(package_name) do
      it { should be_installed }      
    end

    describe service(service_name) do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
