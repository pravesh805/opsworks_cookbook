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
    source "health-check.php.erb"
    mode 0660
    group deployer[:group]
    owner deployer[:name]
    variables(:domain => (app[:domains].first))
  end
 
 
end
