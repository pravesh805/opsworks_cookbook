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

 
node[:deploy].each do |application, deploy|

  template "#{node[:haproxy][:dir]}/ssl/#{deploy[:domains].first}.crt" do
      mode 0600
      source 'haproxy/ssl.key.erb'
      variables :key => deploy[:ssl_certificate]
      only_if do
        deploy[:ssl_support]
      end
  end

  template "#{node[:haproxy][:dir]}/ssl/#{deploy[:domains].first}.key" do
    mode 0600
    source 'haproxy/ssl.key.erb'
    variables :key => deploy[:ssl_certificate_key]
    only_if do
      deploy[:ssl_support]
    end
  end

  template "#{node[:haproxy][:dir]}/ssl/#{deploy[:domains].first}.ca" do
    mode 0600
    source 'haproxy/ssl.key.erb'
    variables :key => deploy[:ssl_certificate_ca]
    only_if do
      deploy[:ssl_support] && deploy[:ssl_certificate_ca]
    end
  end
end

  execute "cat /etc/haproxy/ssl/#{node[:haproxy][:hostname]}.key > /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem &&
  echo ''  >> /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem && 
  cat /etc/haproxy/ssl/#{node[:haproxy][:hostname]}.crt >> /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem &&
  echo ''  >> /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem && 
  cat /etc/haproxy/ssl/#{node[:haproxy][:hostname]}.ca >> /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem"


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

