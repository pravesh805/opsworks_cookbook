#
# Cookbook:: OpsWorks
# Recipe:: haproxy
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

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

bash 'pem_file_existence_and_restart_haproxy' do
  code <<-EOF
    until
      ls -la #{node[:haproxy][:dir]}/ssl/#{node[:haproxy][:cert]}.pem
    do
      echo "Waiting for #{node[:haproxy][:dir]}/ssl/#{node[:haproxy][:cert]}.pem..."
      sleep 1
    done
  EOF
  action :nothing
  notifies :enable, resources(:service => 'haproxy')
  notifies :start, resources(:service => 'haproxy')
  timeout 70
end

search('aws_opsworks_app', 'deploy:true').each do |app|

  template "#{node[:haproxy][:dir]}/ssl/#{app[:domains].first}.crt" do
      mode 0600
      source 'haproxy/ssl.key.erb'
      variables :key => app[:ssl_certificate]
      only_if do
        app[:ssl_support]
      end
  end

  template "#{node[:haproxy][:dir]}/ssl/#{app[:domains].first}.key" do
    mode 0600
    source 'haproxy/ssl.key.erb'
    variables :key => app[:ssl_certificate_key]
    only_if do
      app[:ssl_support]
    end
  end

  template "#{node[:haproxy][:dir]}/ssl/#{app[:domains].first}.ca" do
    mode 0600
    source 'haproxy/ssl.key.erb'
    variables :key => app[:ssl_certificate_ca]
    only_if do
      app[:ssl_support] && app[:ssl_certificate_ca]
    end
  end

  Chef::Log.info("debugging haproxy recipe...")
  Chef::Log.info(app[:ssl_certificate_key])

  ssl_pem = app[:ssl_configuration].try(:[], :private_key) + "\n" + app[:ssl_configuration].try(:[], :certificate) + "\n" + app[:ssl_configuration].try(:[], :chain)

  template "#{node[:haproxy][:dir]}/ssl/#{node[:haproxy][:cert]}.pem" do
    mode 0600
    source 'haproxy/ssl.key.erb'
    variables :key => ssl_pem
    only_if do
      app[:ssl_support] && app[:ssl_certificate] && app[:ssl_certificate_key] && app[:ssl_certificate_ca]
    end
  end


end


execute "echo 'checking if haproxy is not running - if so start it'" do
  not_if "pgrep haproxy"
  notifies :enable, "service[haproxy]"
end
 
bash 'pem_file_existence_and_restart_haproxy' do
  action :run
end