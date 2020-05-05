node.reverse_merge!(
  etcd: {
    server: {
      env: {
        data_dir: '/var/lib/etcd',
        name: '%H',
      },
    },
  },
)

directory '/etc/systemd/system/etcd.service.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end

template '/etc/systemd/system/etcd.service.d/env.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end
