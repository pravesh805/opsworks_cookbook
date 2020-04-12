#
# Cookbook:: OpsWorks
# Recipe:: haproxy-configure
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

Chef::Log.info("Start configuring haproxy....")

template "/etc/haproxy/blacklistedips.ips" do
      source "haproxy/blacklistedips.ips.erb"
      mode 0660

      notifies :restart, "service[haproxy]"
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
        :reverse_proxy  => (node[:haproxy][:reverse_proxy] rescue nil),
        :restricted_page  => (node[:haproxy][:restricted_page] rescue nil),
        # Domain
        :domain           => (node[:haproxy][:hostname]))
      notifies :restart, "service[haproxy]"
end
 
Chef::Log.info("Finished Creating HaProxy cfg...")

template "/etc/default/haproxy" do
      source "haproxy/haproxy-default.erb"
      mode 0660

      variables(:start => (node[:haproxy][:start] rescue nil))
      notifies :restart, "service[haproxy]"
end

service 'haproxy' do
  supports :restart => true, :status => true
  action [:enable, :start]
end