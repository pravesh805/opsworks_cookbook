#
# Cookbook:: OpsWorks
# Recipe:: default
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

execute "update-upgrade" do
  command "sudo apt-get update && sudo apt-get upgrade -y"
  action :run
end

release_user = node[:deployer]["name"]
release_group = node[:deployer]["group"]
group release_group
home = "/home/#{release_user}"

user release_user do
	    action :create
	    comment "deploy user"
	    gid release_group
	    home home
	    supports :manage_home => true
	    shell '/bin/bash'
	    not_if do
	      existing_usernames = []
	      Etc.passwd {|user| existing_usernames << user['name']}
	      existing_usernames.include?(release_user)
	    end
end

package 'git'
package 'tree'
package 'curl'