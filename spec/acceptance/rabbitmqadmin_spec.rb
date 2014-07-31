require 'spec_helper_acceptance'

describe 'rabbitmq::install::rabbitmqadmin class' do
  context 'does nothing if service is unmanaged' do
    it 'should run successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        admin_enable   => true,
        service_manage => false,
      }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      shell('rm -f /var/lib/rabbitmq/rabbitmqadmin')
      apply_manifest(pp, :catch_failures => true)
    end

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { should_not be_file }
    end
  end

  context 'downloads the cli tools' do
    it 'should run successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        admin_enable   => true,
        service_manage => true,
      }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
    end

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { should be_file }
    end
  end

  context 'works with 2.8.1-1' do
    # because the 'inherits params' pattern doesn't work with
    # how we build the package_source default in params.pp
    package_source = 'http://www.rabbitmq.com/releases/rabbitmq-server/v2.8.1/rabbitmq-server-2.8.1-1.noarch.rpm'
    # can't get this confine working. this will only work on yum-based systems
    #confine :to, :platform => 'el-6-x86'

    it 'should run successfully' do
      pp = <<-EOS
      class { 'rabbitmq':
        admin_enable     => true,
        service_manage   => true,
        version          => '2.8.1-1',
        package_source   => '#{package_source}',
        package_ensure   => '2.8.1-1',
        package_provider => 'rpm',
        management_port  => '55672',
      }
      if $::osfamily == 'RedHat' {
        class { 'erlang': epel_enable => true}
        Class['erlang'] -> Class['rabbitmq']
      }
      EOS

      shell('yum -y erase rabbitmq-server')
      shell('rm -Rf /var/lib/rabbitmq/mnesia /etc/rabbitmq')
      apply_manifest(pp, :catch_failures => true)
    end

    # since serverspec (used by beaker-rspec) can only tell present/absent for packages
    describe command('rpm -q rabbitmq-server-2.8.1-1.noarch') do
      it { should return_exit_status 0 }
    end

    describe command('rabbitmqctl status') do
      its(:stdout) { should match /{rabbit,"RabbitMQ","2.8.1"}/ }
    end

    describe file('/var/lib/rabbitmq/rabbitmqadmin') do
      it { should be_file }
    end

    describe command('rabbitmqadmin --help') do
      it { should return_exit_status 0 }
    end

  end
end
