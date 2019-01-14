default['aws']['dir'] = "/var/lib/aws"

default["apache2"]["sites"]["example.com"] = { "port" => 80, "servername" => "example.com", "serveradmin" => "webmaster@example.com" }
# Default configuration for the AWS OpsWorks cookbook for Wordpress
#

# Enable the Wordpress W3 Total Cache plugin (http://wordpress.org/plugins/w3-total-cache/)?
default['wordpress']['wp_config']['enable_W3TC'] = false

# Force logins via https (http://codex.wordpress.org/Administration_Over_SSL#To_Force_SSL_Logins_and_SSL_Admin_Access)
default['wordpress']['wp_config']['force_secure_logins'] = false

#apache
default['apache']['dir']     = "/etc/apache2"
default[:apache][:document_root] = '/var/www/html'
default[:apache][:log_dir]       = '/var/log/apache2'

#haproxy
default['haproxy']['dir']     = "/etc/haproxy"
default['haproxy']['inter']     = "2s"
default['haproxy']['fall']     = "2"
#Varnish configrations
default['varnish']['dir']     = "/etc/varnish"
default['varnish']['default'] = "/etc/default/varnish"
default['varnish']['service'] = "/lib/systemd/system/varnish.service"
default['varnish']['start'] = 'yes'
default['varnish']['nfiles'] = 131072
default['varnish']['memlock'] = 82000
default['varnish']['instance'] = node['hostname']
default['varnish']['listen_address'] = ''
#default['varnish']['listen_port'] = 443
default['varnish']['vcl_conf'] = 'default.vcl'
default['varnish']['vcl_source'] = 'varnish-default.vcl.erb'
default['varnish']['vcl_cookbook'] = nil
default['varnish']['secret_file'] = '/etc/varnish/secret'
default['varnish']['admin_listen_address'] = '127.0.0.1'
default['varnish']['admin_listen_port'] = '6082'
default['varnish']['user'] = 'varnish'
default['varnish']['group'] = 'varnish'
default['varnish']['ttl'] = '120'
default['varnish']['min_threads'] ='5'
default['varnish']['max_threads'] = '500'
default['varnish']['thread_timeout'] = '300'
#default['varnish']['storage'] = 'file'
default['varnish']['storage_file'] = '/var/lib/varnish/$INSTANCE/varnish_storage.bin'
#default['varnish']['storage_size'] = '1G'

default['varnish']['storage'] = 'malloc'
default['varnish']['storage_size'] = '256m'

default['varnish']['backend_host'] = '127.0.0.1'
