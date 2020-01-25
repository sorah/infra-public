node.reverse_merge!(
  ami: {
    role: 'ecs',
    set_hostname: false,
  },
)
include_cookbook 'ami'
include_cookbook 'aws-sdk-ruby'

remote_file '/usr/bin/ecs-ami-startup' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/systemd/system/ecs-ami-startup.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'ecs.service' do
  action [:enable]
end

service 'ecs-ami-startup.service' do
  action [:enable]
end
