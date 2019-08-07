#
# Cookbook:: OpsWorks
# Recipe:: apache
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

Chef::Log.info("Configuring Apache......")

package "apache2" do
  action :install
end

service "apache2" do
  action [:enable, :start]
end

directory "#{node[:apache][:dir]}/ssl" do
  action :create
  mode 0755
  owner 'root'
  group 'root'
end

bash 'logdir_existence_and_restart_apache2' do
  code <<-EOF
    until
      ls -la #{node[:apache][:log_dir]}
    do
      echo "Waiting for #{node[:apache][:log_dir]}..."
      sleep 1
    done
  EOF
  action :nothing
  notifies :restart, resources(:service => 'apache2')
  timeout 70
end

execute "disable-sites" do
    command "a2dissite 000-default.conf"
    action :run
end

Chef::Log.info("Create Htpasswd File......Level:#{node[:apache][:protection]}")
if !(node[:apache][:protection].nil? || node[:apache][:protection].empty?)
  # Create htpasswd file
  Chef::Log.info("running htpasswd....")
  apache_user = (node[:apache][:htpasswd][:user] rescue nil)
  apache_password = (node[:apache][:htpasswd][:password] rescue nil)
  Chef::Log.info("htpasswd -cb /etc/htpasswd #{apache_user} #{apache_password}")
  execute "run-htpasswd" do
    command "htpasswd -cb /etc/htpasswd #{apache_user} #{apache_password}"
    action :run
  end
end

apache_ports = []

node[:deploy].each do |app, deploy|
  if(defined?(deploy[:apache]))
    Chef::Log.info("apache port configured #{deploy[:apache][:port]}")
    apache_ports << deploy[:apache][:port]
  end
end

template "/etc/apache2/ports.conf" do
  source "apache-ports.erb"
  group 'root'
  owner 'root'
  mode 0644
  variables(
    :ports => apache_ports
  )
  notifies :run, resources(:bash => 'logdir_existence_and_restart_apache2')
end

template "/etc/apache2/apache2.conf" do
  source "apache2.conf.erb"
  owner 'root'
  group 'root'
  mode 0644
  notifies :run, resources(:bash => 'logdir_existence_and_restart_apache2')
end

execute "enable-rewrite" do
  command "a2enmod rewrite"
  action :run
end

execute "enable-headers" do
  command "a2enmod headers"
  action :run
end

execute "enable-proxy" do
  command "a2enmod proxy"
  action :run
end

execute "enable-proxy-http" do
  command "a2enmod proxy_http"
  action :run
end

execute "enable-proxy-html" do
  command "a2enmod proxy_html"
  action :run
end

execute "enable-ssl" do
    command "a2enmod ssl"
    action :run
end


Chef::Log.info("Create Virtual Hosts Files......")
#Virtual Hosts Files
search('aws_opsworks_app', 'deploy:true').each do |app|
  if(!node[:deploy][app[:shortname]][:enabled])
    Chef::Log.info("Skipping apache config for application #{app[:shortname]}")
    next
  end
  document_root = "/srv/www/#{app[:shortname]}/" + node[:deploy][app[:shortname]][:apache][:document_root]
  release_user = node[:deployer]["name"]
  release_group = node[:deployer]["group"]
  # directory document_root do
  #   mode "0755"
  #   group release_group
  #   owner release_user
  #   recursive true
  # end
 
  template "/etc/apache2/sites-available/#{app[:shortname]}.conf" do
    source "virtualhosts.erb"
    mode "0644"
    variables(
      :document_root => document_root,
      :port => node[:deploy][app[:shortname]][:apache]["port"],
      :name => app[:shortname],
      :ssl_enabled => node[:deploy][app[:shortname]][:apache]["ssl_enabled"],
      :servername => app[:domains].first
    )
    notifies :run, "execute[enable-sites]"
    notifies :restart, "service[apache2]"
  end

  execute "enable-sites" do
    command "a2ensite #{app[:shortname]}"
    action :run
  end

  execute "keepalive" do
    command "sed -i 's/KeepAlive On/KeepAlive Off/g' /etc/apache2/apache2.conf"
    action :run
  end

  template "#{node[:apache][:dir]}/ssl/#{app[:domains].first}.crt" do
      mode 0600
      source 'apache/ssl.key.erb'
      variables :key => app[:ssl_configuration][:certificate]
      only_if do
        app[:enable_ssl] && app[:ssl_configuration][:certificate]
      end
  end

  template "#{node[:apache][:dir]}/ssl/#{app[:domains].first}.key" do
    mode 0600
    source 'apache/ssl.key.erb'
    variables :key => app[:ssl_configuration][:private_key]
    only_if do
      app[:enable_ssl] && app[:ssl_configuration][:private_key]
    end
  end

  template "#{node[:apache][:dir]}/ssl/#{app[:domains].first}.ca" do
    mode 0600
    source 'apache/ssl.key.erb'
    variables :key => app[:ssl_configuration][:chain]
    only_if do
      app[:enable_ssl] && app[:ssl_configuration][:chain]
    end
  end

   

  # execute "enable-event" do
  #   command "a2enmod mpm_event"
  #   action :nothing
  # end

  # cookbook_file "/etc/apache2/mods-available/mpm_event.conf" do
  #   source "mpm_event.conf"
  #   mode "0644"
  #   notifies :run, "execute[enable-event]"
  # end


end

bash 'logdir_existence_and_restart_apache2' do
  action :run
end

file "#{node[:apache][:document_root]}/index.html" do
  action :delete
  backup false
  only_if do
    File.exists?("#{node[:apache][:document_root]}/index.html")
  end
end


