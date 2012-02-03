include_recipe 'moodle::php-fcgi'
include_recipe 'nginx'

cookbook_file '/etc/nginx/fastcgi_params' do  
  source "fastcgi_params.conf"
  mode 0644
  owner "root"
  group "root"
  notifies :reload, resources(:service => "nginx")
end