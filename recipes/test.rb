

# execute "cat /etc/haproxy/ssl/#{node[:haproxy][:hostname]}.key > /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem &&
#   echo ''  >> /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem && 
#   cat /etc/haproxy/ssl/#{node[:haproxy][:hostname]}.crt >> /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem &&
#   echo ''  >> /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem && 
#   cat /etc/haproxy/ssl/#{node[:haproxy][:hostname]}.ca >> /etc/haproxy/ssl/#{node[:haproxy][:cert]}.pem"

ssl_key = "ssl_key"
ssl_ca = "ssl_ca"
ssl_crt = "ssl_crt"

ssl_pem = ""

ssl_pem = ssl_key+"\n"+ssl_crt+"\n"+ssl_crt

puts ssl_pem
