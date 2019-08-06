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

  script "generate_swagger_docs" do
    interpreter "bash"
    user "deploy"
    cwd "#{deploy_to}/current"
    code <<-EOH
    php artisan lebara-swagger:generate
    EOH
    only_if { ::File.exist?("#{deploy_to}/current/composer.json")}
  end

  directory "/srv/www/#{app[:shortname]}/current/storage" do
    action :create
    recursive true
    mode 0775
    only_if { ::File.exist?("#{deploy_to}/current/composer.json")}
  end
end