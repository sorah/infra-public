include_cookbook 'loopback'

remote_file "/etc/modules-load.d/fou.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
end

remote_file "/etc/sysctl.d/90-fou.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
end

remote_file "/usr/bin/nkmi-setup-gue-receive" do
  owner 'root'
  group 'root'
  mode  '0755'
end

template "/etc/systemd/system/nkmi-setup-gue-receive.service" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'nkmi-setup-gue-receive.service' do
  action [:enable, :start]
end
