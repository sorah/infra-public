remote_file '/etc/systemd/networkd.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
end

service 'systemd-networkd' do
  action :nothing
end

