#
# Cookbook:: OpsWorks
# Recipe:: configure
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

# Create the Wordpress config file wp-config.php with corresponding values

search('aws_opsworks_app', 'deploy:true').each do |app|
  Chef::Log.info("Configuring Lumen app #{app[:shortname]}...")

  deploy = node[:deploy]["#{app[:shortname]}"]

  if defined?(deploy[:application_type]) && deploy[:application_type] != 'lumen'
    Chef::Log.info("Skipping Lumen Configure  application #{app[:shortname]} as it is not defined as")
    next
  end

  create_deploy_dir(app, File.join('shared'))
  create_deploy_dir(app, File.join('shared', 'config'))
  create_deploy_dir(app, File.join('shared', 'log'))
  create_deploy_dir(app, File.join('shared', 'scripts'))
  create_deploy_dir(app, File.join('shared', 'sockets'))
  create_deploy_dir(app, File.join('shared', 'system'))
  create_dir("/run/lock/#{app['shortname']}")

  pids_link_path = File.join(deploy_dir(app), 'shared', 'pids')
  link pids_link_path do
    to "/run/lock/#{app['shortname']}"
    not_if { ::File.exist?(pids_link_path) }
  end
  
  deployer= node[:deployer]
  apache = node[:apache]
  apache_user = (apache[:ap_user] rescue nil)
  apache_password = (apache[:ap_password] rescue nil)
  deploy_to = "/srv/www/#{app[:shortname]}"

  template "#{deploy_to}/shared/config/.env" do
    source "env.erb"
    mode 0660
    group deployer[:group]
    owner deployer[:name]

    variables(
      :configs  => (deploy[:configs] rescue nil),
  end

  template "#{deploy_to}/shared/config/health-check.php" do
    source "health-check-lumen.php.erb"
    mode 0660
    group deployer[:group]
    owner deployer[:name]
    variables(:domain => (app[:domains].first))
  end
 
 
end
