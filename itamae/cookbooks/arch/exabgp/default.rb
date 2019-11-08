package 'python-setuptools' # FIXME:
package 'exabgp'

user 'exabgp' do
  system_user true
end

remote_file '/etc/systemd/system/exabgp.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

directory '/etc/exabgp' do
  owner 'root'
  group 'root'
  mode  '0755'
end
