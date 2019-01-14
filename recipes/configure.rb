#
# Cookbook:: OpsWorks
# Recipe:: configure
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

# Create the Wordpress config file wp-config.php with corresponding values

search('aws_opsworks_app', 'deploy:true').each do |app|
  Chef::Log.info("Configuring WP app #{app[:shortname]}...")

  if defined?(deploy[:application_type]) && deploy[:application_type] != 'php'
    Chef::Log.info("Skipping WP Configure  application #{app[:shortname]} as it is not defined as")
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


  deploy = node[:deploy]["#{app[:shortname]}"]
  deployer= node[:deployer]
  apache = node[:apache]
  apache_user = (apache[:ap_user] rescue nil)
  apache_password = (apache[:ap_password] rescue nil)
  deploy_to = "/srv/www/#{app[:shortname]}"

  template "#{deploy_to}/shared/config/keys.php" do
    source "keys.php.erb"
    mode 0660
    group deployer[:group]
    owner deployer[:name]

    variables(
      # DB configuration
      :database         => (deploy[:database][:database] rescue nil),
      :user             => (deploy[:database][:username] rescue nil),
      :password         => (deploy[:database][:password] rescue nil),
      :host             => (deploy[:database][:host] rescue nil),
      :table_prefix             => (deploy[:database][:prefix] rescue nil),

      # authentication
      :auth_key         => (deploy[:authentication][:auth_key] rescue nil),
      :secret_auth_key  => (deploy[:authentication][:secret_auth_key] rescue nil),
      :logged_in_key    => (deploy[:authentication][:logged_in_key] rescue nil),
      :nonce_key        => (deploy[:authentication][:nonce_key] rescue nil),
      :auth_salt        => (deploy[:authentication][:auth_salt] rescue nil),
      :secure_auth_salt => (deploy[:authentication][:secure_auth_salt] rescue nil),
      :logged_in_salt   => (deploy[:authentication][:logged_in_salt] rescue nil),
      :nonce_salt       => (deploy[:authentication][:nonce_salt] rescue nil),

      # AWS keys
      :s3_access_key    => (deploy[:aws][:s3_access_key] rescue nil),
      :s3_secret_key    => (deploy[:aws][:s3_secret_key] rescue nil),
      :s3_bucket    => (deploy[:aws][:s3_bucket] rescue nil),
      :s3_region    => (deploy[:aws][:s3_region] rescue nil),
      :cf_id    => (deploy[:aws][:cf_id] rescue nil),
      :redis_url    => (deploy[:aws][:redis][:url] rescue nil),
      :redis_client    => (deploy[:aws][:redis][:client] rescue nil),

      #SMTP 
      :smtp_user   => (deploy[:smtp][:user] rescue nil),
      :smtp_password   => (deploy[:smtp][:password] rescue nil),
      :smtp_host    => (deploy[:smtp][:host] rescue nil),
      :smtp_email    => (deploy[:smtp][:email] rescue nil),
      :smtp_name    => (deploy[:smtp][:name] rescue nil),
      :smtp_port   => (deploy[:smtp][:port] rescue nil),

      :configs  => (deploy[:configs] rescue nil),

      #google keys
      :google_map_api_key    => (deploy[:google][:map_api_key] rescue nil),
      
      :google_recaptcha_key_v2    => (deploy[:google][:recaptcha_key_v2] rescue nil),
      :google_recaptcha_secret_key_v2    => (deploy[:google][:recaptcha_secret_key_v2] rescue nil),
     
      :google_recaptcha_key_invisible    => (deploy[:google][:recaptcha_key_invisible] rescue nil),
      :google_recaptcha_secret_key_invisible    => (deploy[:google][:recaptcha_secret_key_invisible] rescue nil),

      # Domain
      :domain           => (app[:domains].first))
  end

  template "#{deploy_to}/shared/config/health-check.php" do
    source "health-check.php.erb"
    mode 0660
    group deployer[:group]
    owner deployer[:name]
    variables(:domain => (app[:domains].first))
  end

  template "#{node[:aws][:dir]}/config" do
    source "aws/config.erb"
    group 'root'
    owner 'root'
    mode 0644
    variables(
      :region => (deploy[:aws][:s3_region] rescue nil)
    )
  end

  template "#{node[:aws][:dir]}/credentials" do
    source "aws/credentials.erb"
    group 'root'
    owner 'root'
    mode 0644
    variables(
      :aws_access_key_id => (deploy[:aws][:s3_access_key] rescue nil),
      :aws_secret_access_key => (deploy[:aws][:s3_secret_key] rescue nil),
      :aws_region => (deploy[:aws][:s3_region] rescue nil)
    )
  end

 
end
