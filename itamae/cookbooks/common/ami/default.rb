node.reverse_merge!(
  ami: {
    role: nil,
    set_hostname: true,
  },
)

raise "node.ami.role is required" unless node[:ami][:role]

remote_file '/usr/bin/nkmi-ami-startup' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/systemd/system/nkmi-ami-startup.service' do
  owner 'root'
  group 'root'
  mode  '0644'
end

file '/etc/nkmi-ami-startup.json' do
  content "#{node[:ami].to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

service 'nkmi-ami-startup.service' do
  action :enable
end
