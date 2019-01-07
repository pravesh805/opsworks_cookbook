#
# Cookbook:: OpsWorks
# Recipe:: services-restart
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

execute "service apache2 restart" 
execute "service varnish restart" 