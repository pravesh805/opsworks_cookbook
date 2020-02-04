#
# Cookbook:: OpsWorks
# Recipe:: php
#
# Copyright:: 2018, Moayyad Faris, All Rights Reserved.

package "php" do
  action :install
end

package "php-pear" do
  action :install
end

package "php-curl" do
  action :install
end

package "php-mysql" do
  action :install
end

apt_package "php-fpm" do
action :install
end

apt_package "php7.2-fpm" do
action :install
end

apt_package "php7.2-zip" do
action :install
end

apt_package "php7.2-mbstring" do
action :install
end

apt_package "php7.2-xml" do
action :install
end

apt_package "imagemagick" do
action :install
end

apt_package "php-imagick" do
  action :install
end


# cookbook_file "/etc/php/7.0/cli/php.ini" do
#   source "php.ini"
#   mode "0644"
#   notifies :restart, "service[apache2]"
# end


execute "chownlog" do
  command "chown www-data /var/log/php"
  action :nothing
end

directory "/var/log/php" do
  action :create
  notifies :run, "execute[chownlog]"
end