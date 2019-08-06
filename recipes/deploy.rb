#
# Cookbook:: OpsWorks
# Recipe:: deploy
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

Chef::Log.info("Start deplying the app....")

prepare_recipe
include_recipe 'OpsWorks::configure'

search('aws_opsworks_app', 'deploy:true').each do |app|
	Chef::Log.info("********** Starting To Deploy App: '#{app[:name]}' **********")
	 
	deploy_to = "/srv/www/#{app[:shortname]}"
	symbolic_release_path = "/srv/www/#{app[:shortname]}/current"
	release_user = node[:deployer]["name"]
    release_group = node[:deployer]["group"]

    is_vagrant = false
    home = "/home/#{release_user}"

 	group release_group

 	
	Chef::Log.info("********** Working on Apache For App: '#{app[:name]}' **********")

	 
	if is_vagrant == false

	    Chef::Log.info("********** Getting The App From SCM: '#{app[:name]}' **********")

	    directory "#{deploy_to}" do
	      group release_group
	      owner release_user
	      mode "0775"
	      action :create
	      recursive true
	    end

	    app_source = app[:app_source]

	    prepare_git_checkouts(
	        :user => release_user,
	        :group => release_group,
	        :home => home,
	        :ssh_key => app_source[:ssh_key]
	    ) if app_source[:type].to_s == 'git'

	    app_symlink = ['log', 'tmp/pids', 'public/system']

	    {"config/keys.php" => "keys.php", "config/health-check.php" => "health-check.php"}
	    symlinks_list = []
	    symlinks = node[:deploy][app[:shortname]][:symlinks]
	    symlinks.each do |key, value|
	    	symlinks_list << value
	    end
	    app_symlink << symlinks_list

	    create_symlink = {"system" => "public/system", "pids" => "tmp/pids", "log" => "log"}
	    symlinks.each do |key, value|
	    	create_symlink << {key => value}
	    end
	    deploy deploy_to do
	      provider Chef::Provider::Deploy::Timestamped
	      keep_releases 2
	      repository app_source[:url]
	      user release_user
	      group release_group
	      revision app_source[:revision]
	      migrate false
	      environment({"HOME" => home, "APP_NAME" => app[:shortname]})
	      purge_before_symlink(app_symlink)
	      create_dirs_before_symlink(['tmp', 'public', 'config'])
	      symlink_before_migrate({})
	      symlinks(create_symlink)
	      action :deploy

	      case app_source[:type].to_s
	        when 'git'
	          scm_provider Chef::Provider::Git
	          enable_submodules true
	          depth 1
	        when 'svn'
	          scm_provider Chef::Provider::Subversion
	          svn_username app_source[:user]
	          svn_password app_source[:password]
	          svn_arguments "--no-auth-cache --non-interactive --trust-server-cert"
	          svn_info_args "--no-auth-cache --non-interactive --trust-server-cert"
	        else
	          raise "unsupported SCM type #{app_source[:type].inspect}"
	      end
	    end
	else
		Chef::Log.info("********** Running Symlink Recipes '#{app[:name]}' **********")
		include_recipe "deploy::before_symlink"
		include_recipe "deploy::after_restart"
	end
end

 