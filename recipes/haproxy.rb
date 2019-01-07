#
# Cookbook:: OpsWorks
# Recipe:: haproxy
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

package 'haproxy' do
  action :install
end

directory "#{node[:haproxy][:dir]}/ssl" do
  action :create
  mode 0755
  owner 'root'
  group 'root'
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


template "/etc/haproxy/haproxy.cfg" do
      source "haproxy/haproxy.cfg.erb"
      mode 0660

      variables(
        :protection         => (node[:haproxy][:protection] rescue nil),
        :allowed_pass         => (node[:haproxy][:allowed_pass] rescue nil),
        :cert         => (node[:haproxy][:cert] rescue nil),
        :backend_host  => (node[:haproxy][:backend_host] rescue nil),
        :backend_port  => (node[:haproxy][:backend_port] rescue nil),
        # Domain
        :redirect_domain           => (node[:haproxy][:hostname]))
      notifies :restart, "service[haproxy]"
end
 
Chef::Log.info("Finished Creating HaProxy cfg...")

template "/etc/default/haproxy" do
      source "haproxy/haproxy-default.erb"
      mode 0660

      variables(:start => (node[:haproxy][:start] rescue nil))
      notifies :restart, "service[haproxy]"
end


execute "echo 'checking if haproxy is not running - if so start it'" do
  not_if "pgrep haproxy"
  notifies :start, "service[haproxy]"
end
 
service 'haproxy' do
  supports :restart => true, :status => true
  action [:enable, :start]
end

