node.reverse_merge!(
  docker: {
    daemon_config: {
      'storage-driver' => 'overlay2',
      'bip' => '10.10.38.1/24',
      'default-address-pool' => [base: '10.38.0.0/20', size: 23],
    },
  },
)

package 'docker'

directory '/etc/docker' do
  owner 'root'
  group 'root'
  mode  '0755'
end

file "/etc/docker/daemon.json" do
  content "#{node[:docker][:daemon_config].to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

directory '/etc/systemd/system/docker.service.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end

template '/etc/systemd/system/docker.service.d/dependencies.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'docker' do
  action [:enable, :start]
end
