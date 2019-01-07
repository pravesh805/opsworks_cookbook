#
# Cookbook:: OpsWorks
# Recipe:: wp-create-upload-dir
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

search('aws_opsworks_app', 'deploy:true').each do |app|
	Chef::Log.info("Creating upload directory for #{app}...")

	if defined?(deploy[:application_type]) && deploy[:application_type] != 'php'
		Chef::Log.info("Skipping WP Configure  application #{app[:shortname]} as it is not defined")
		next
	end

	deploy_to = "/srv/www/#{app[:shortname]}"

    Chef::Log.info("Start on creating upload directory")
    
	directory "#{deploy_to}/current/wp-content/uploads" do
	    mode 0775
	    recursive true
	    group node[:deployer][:group]
	    owner node[:deployer][:name]
	    action :create
	end
    Chef::Log.info("End on creating upload directory")

end

 
