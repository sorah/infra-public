template '/etc/systemd/system/nkmi-mnt-vol.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'nkmi-mnt-vol.service' do
  action :enable
end
