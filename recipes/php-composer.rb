search('aws_opsworks_app', 'deploy:true').each do |app|
  deploy_to = "/srv/www/#{app[:shortname]}"
  script "install_composer" do
    interpreter "bash"
    user "root"
    cwd "#{deploy_to}/current"
    code <<-EOH
    curl -s https://getcomposer.org/installer | php
    php composer.phar install --no-dev --no-interaction --prefer-dist
    EOH
    only_if { ::File.exist?("#{deploy_to}/current/composer.json")}
  end
end