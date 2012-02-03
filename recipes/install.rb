include_recipe 'mysql::server'
include_recipe 'moodle::nginx'
include_recipe 'git'

directory "#{node[:moodle][:dir]}" do
  owner "www-data"
  group "www-data"
  mode "0755"
  action :create
  recursive true
end

bash "Install moodle software" do
  cwd '/tmp'
  code <<-EOS
  git clone -b MOODLE_21_STABLE git://git.moodle.org/moodle.git
  mv moodle/* #{node[:moodle][:dir]}
  rm -rf moodle
EOS
  user "www-data"
  group "www-data"
  notifies :run, resources(:execute => "ensure correct permissions"), :immediately 
end

template "#{node[:nginx][:dir]}/sites-available/moodle" do
  source "nginx-site.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

nginx_site "moodle" do
  notifies :restart, 'service[nginx]', :inmediately
end

if ['localhost', node.fqdn].include?(node[:moodle][:db][:host])
  
  execute "Grant DB permissions for Moodle" do
    command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} < /etc/mysql/moodle-grants.sql"
    action :nothing
  end
  
  template "/etc/mysql/moodle-grants.sql" do
    path "/etc/mysql/moodle-grants.sql"
    source "grants.sql.erb"
    owner "root"
    group "root"
    mode "0600"
    variables(:database => node[:moodle][:db])
    notifies :run, "execute[Grant DB permissions for Moodle]", :immediately
  end

  execute "Create #{node[:moodle][:db][:database]} database for Moodle" do
    command "/usr/bin/mysqladmin -u root -p#{node[:mysql][:server_root_password]} create #{node[:magento][:db][:database]}"
  end

  # save node data after writing the MYSQL root password, so that a failed chef-client run that gets this far doesn't cause an unknown password to get applied to the box without being saved in the node data.
  ruby_block "save node data" do
    block do
      node.save
    end
    action :create
  end
end





	#
	# Configuración de Moodle
	#
	echo -n "+ Configurando Moodle"
	mkdir -p ${EBS_DIR}/common/moodle/etc
	COOKIE=`curl -i -s http://cudis.centroceleo.es/install.php | grep Set-Cookie | cut -d: -f2- | awk '{ printf $1}'`
	cd
	curl -i -s --cookie "$COOKIE" --data "language=es_es_utf8&stage=0&next=Siguiente%20%20»" http://cudis.centroceleo.es/install.php >moodle-configuration-step00.php 
	curl -i -s --cookie "$COOKIE" --data "stage=1&next=Siguiente%20%20»" http://cudis.centroceleo.es/install.php >moodle-configuration-step01.php 
	curl -i -s --cookie "$COOKIE" --data "stage=2&wwwrootform=http://cudis.centroceleo.es&dirrootform=/usr/share/moodle&dataroot=/var/lib/moodle&next=Siguiente%20%20»" http://cudis.centroceleo.es/install.php >moodle-configuration-step02.php 
	curl -i -s --cookie "$COOKIE" --data "stage=3&dbtype=mysql&dbhost=$MOODLE_DB_HOST&dbname=$MOODLE_DB_NAME&dbuser=$MOODLE_DB_USER&dbpass=$MOODLE_DB_PASSWORD&prefix=mdl_&next=Siguiente%20%20»" http://cudis.centroceleo.es/install.php >moodle-configuration-step03.php 
	curl -i -s --cookie "$COOKIE" --data "stage=5&next=Siguiente%20%20»" http://cudis.centroceleo.es/install.php >moodle-configuration-step04.php 
	curl -i -s --cookie "$COOKIE" --data "stage=6&downloadlangpack=1&same=1" http://cudis.centroceleo.es/install.php >moodle-configuration-step05.php 
	curl -i -s --cookie "$COOKIE" --data "stage=6&next=Siguiente%20%20»" http://cudis.centroceleo.es/install.php >moodle-configuration-step06.php 
	curl -s --cookie "$COOKIE" "http://cudis.centroceleo.es/install.php?download=1" >${EBS_DIR}/common/moodle/etc/config.php
	
mkdir -p /etc/moodle
ln -s ${EBS_DIR}/common/moodle/etc/config.php /etc/moodle/config.php
ln -s /etc/moodle/config.php /usr/share/moodle/config.php
chmod 644 ${EBS_DIR}/common/moodle/etc/config.php
echo " [Correcto]"





template '/etc/cron.d/moodle' do
  source 'cron.erb'
  owner "root"
  group "root"
  mode 0644
end

bash "Restart cron" do
  code '/usr/bin/service cron restart'
  user 'root'
end
