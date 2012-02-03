include_recipe %w{apache2 apache2::mod_deflate apache2::mod_expires apache2::mod_headers apache2::mod_rewrite apache2::mod_ssl apache2::mod_php5}

server_fqdn = node.fqdn

sites = %w(moodle)

if node[:moodle][:secure]
  bash "Create SSL Certificates" do
    cwd "#{node[:apache][:dir]}/ssl"
    code <<-EOH
    umask 022
    openssl genrsa 2048 > #{node[:moodle][:server_name]}.key
    openssl req -batch -new -x509 -days 365 -key #{node[:moodle][:server_name]}.key -out #{node[:moodle][:server_name]}.crt
    cat #{node[:moodle][:server_name]}.crt #{node[:moodle][:server_name]n}.key > #{node[:moodle][:server_name]}.pem
    EOH
    only_if { File.zero?("#{node[:apache][:dir]}/ssl/#{server_fqdn}.pem") }
    action :nothing
  end

  cookbook_file "#{node[:apache][:dir]}/ssl/#{node[:moodle][:server_name]}.pem" do
    source "cert.pem"
    mode 0644
    owner "root"
    group "root"
    notifies :run, resources(:bash => "Create SSL Certificates"), :immediately
  end
  
  sites << 'moodle_ssl'
end

sites.each do |site|
  web_app "#{site}" do
    template "apache-site.conf.erb"
    docroot "#{node[:moodle][:dir]}"
    server_name node[:moodle][:server_name]
    server_aliases node.fqdn
    ssl (site == "moodle_ssl")?true:false
  end
end

%w{default 000-default}.each do |site|
  apache_site "#{site}" do
    enable false
  end
end

execute "ensure correct permissions" do
  command "chown -R #{node[:apache][:user]}:#{node[:apache][:user]} #{node[:moodle][:dir]} && chmod -R g+rw #{node[:moodle][:dir]}"
  action :nothing
  notifies :restart, resources(:service => "apache2"), :immediately
end