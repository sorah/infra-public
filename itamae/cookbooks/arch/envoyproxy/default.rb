include_cookbook 'http-user'
package 'envoyproxy'

remote_file '/usr/bin/envoyproxy-hot-restarter.py' do
  owner 'root'
  group 'root'
  mode  '0755'
end
template '/usr/bin/envoyproxy-start.sh' do
  owner 'root'
  group 'root'
  mode  '0755'
end
directory '/etc/envoyproxy' do
  owner 'root'
  group 'root'
  mode  '0755'
end

template '/etc/systemd/system/envoyproxy@.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end
