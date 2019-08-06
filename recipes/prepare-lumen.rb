search('aws_opsworks_app', 'deploy:true').each do |app|
  deploy_to = "/srv/www/#{app[:shortname]}"
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
    recursive: true
    mode 0775
    only_if { ::File.exist?("#{deploy_to}/current/composer.json")}
  end
end