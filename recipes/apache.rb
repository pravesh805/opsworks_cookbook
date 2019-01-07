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

template "/etc/apache2/ports.conf" do
  source "apache-ports.erb"
  group 'root'
  owner 'root'
  mode 0644
  variables(
    :port => node[:apache]["port"]
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


Chef::Log.info("Create Virtual Hosts Files......")
#Virtual Hosts Files
search('aws_opsworks_app', 'deploy:true').each do |app|
  document_root = "/srv/www/#{app[:shortname]}/current"
  release_user = node[:deployer]["name"]
  release_group = node[:deployer]["group"]
  # directory document_root do
  #   mode "0755"
  #   group release_group
  #   owner release_user
  #   recursive true
  # end

  execute "enable-sites" do
    command "a2ensite #{app[:shortname]}"
    action :nothing
  end
 
  template "/etc/apache2/sites-available/#{app[:shortname]}.conf" do
    source "virtualhosts.erb"
    mode "0644"
    variables(
      :document_root => document_root,
      :port => node[:apache]["port"],
      :name => app[:shortname],
      :servername => app[:domains].first
    )
    notifies :run, "execute[enable-sites]"
    notifies :restart, "service[apache2]"
  end

  execute "keepalive" do
    command "sed -i 's/KeepAlive On/KeepAlive Off/g' /etc/apache2/apache2.conf"
    action :run
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

