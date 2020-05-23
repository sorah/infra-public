node.reverse_merge!(
  thanos: {
    objstore: {
      
    },
  },
)

include_cookbook 'thanos'

template '/etc/systemd/system/thanos-sidecar.service.d/exec.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end


file '/etc/thanos/objstore.yml' do
  content "#{node[:thanos][:objstore].to_json}\n"
  owner 'thanos'
  group 'prometheus'
  mode  '0640'
end


service 'thanos-sidecar.service' do
  action [:enable, :start]
end
