

include_recipe %w(php php::module_gd php::module_curl php::module_mysql php::module_ldap)

package %w(php5-cgi spawn-fcgi php5-xmlrpc)

cookbook_file '/usr/bin/php-fastcgi' do
  source "php-fcgi.sh"
  mode 0755
  owner "root"
  group "root"
end

cookbook_file '/etc/init.d/php-fastcgi' do
  source "php-fcgi.init.d.sh"
  mode 0755
  owner "root"
  group "root"
end

bash "Launch PHP Fast CGI Spawner" do
  code "/etc/init.d/php-fastcgi restart"
  user 'root'
end

