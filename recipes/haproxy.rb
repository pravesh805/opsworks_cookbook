#
# Cookbook:: OpsWorks
# Recipe:: haproxy
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

Chef::Log.info("Start deplying haproxy....")

package 'haproxy' do
  action :install
end

service "haproxy" do
  action [:enable, :start]
end

directory "#{node[:haproxy][:dir]}/ssl" do
  action :create
  mode 0755
  owner 'root'
  group 'root'
end

# bash 'pem_file_existence_and_restart_haproxy' do
#   code <<-EOF
#     until
#       ls -la #{node[:haproxy][:dir]}/ssl/#{node[:haproxy][:cert]}.pem
#     do
#       echo "Waiting for #{node[:haproxy][:dir]}/ssl/#{node[:haproxy][:cert]}.pem..."
#       sleep 1
#     done
#   EOF
#   action :nothing
#   notifies :enable, resources(:service => 'haproxy')
#   notifies :start, resources(:service => 'haproxy')
#   timeout 70
# end

search('aws_opsworks_app', 'deploy:true').each do |app|
  template "#{node[:haproxy][:dir]}/ssl/#{app[:domains].first}.crt" do
      mode 0600
      source 'haproxy/ssl.key.erb'
      variables :key => app[:ssl_configuration][:certificate]
      only_if do
        app[:enable_ssl] && app[:ssl_configuration][:certificate]
      end
  end

  template "#{node[:haproxy][:dir]}/ssl/#{app[:domains].first}.key" do
    mode 0600
    source 'haproxy/ssl.key.erb'
    variables :key => app[:ssl_configuration][:private_key]
    only_if do
      app[:enable_ssl] && app[:ssl_configuration][:private_key]
    end
  end

  template "#{node[:haproxy][:dir]}/ssl/#{app[:domains].first}.ca" do
    mode 0600
    source 'haproxy/ssl.key.erb'
    variables :key => app[:ssl_configuration][:chain]
    only_if do
      app[:enable_ssl] && app[:ssl_configuration][:chain]
    end
  end

  Chef::Log.info("debugging haproxy recipe...")

  ssl_pem = app[:ssl_configuration][:private_key] + "\n" + app[:ssl_configuration][:certificate] + "\n" + app[:ssl_configuration][:chain]

  template "#{node[:haproxy][:dir]}/ssl/#{node[:haproxy][:cert]}.pem" do
    mode 0600
    source 'haproxy/ssl.key.erb'
    variables :key => ssl_pem
    only_if do
      app[:enable_ssl] && app[:ssl_configuration][:certificate] && app[:ssl_configuration][:private_key] && app[:ssl_configuration][:chain]
    end
  end
end

execute "echo 'checking if haproxy is not running - if so start it'" do
  not_if "pgrep haproxy"
  notifies :start, "service[haproxy]"
end

service 'haproxy' do
  supports :restart => true, :status => true
  action [:enable, :start]
end