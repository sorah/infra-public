include_cookbook 'vault'

directory '/etc/nkmi-vault-renew.d' do
  owner 'root'
  group 'root'
  mode  '0700'
end

remote_file '/usr/bin/nkmi-vault-renew' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/systemd/system/nkmi-vault-renew.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

remote_file '/etc/systemd/system/nkmi-vault-renew.timer' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'nkmi-vault-renew.timer' do
  action [:enable, :start]
end
