node.reverse_merge!(
  mackerel_agent: {
    api_key: node[:secrets][:'mackerel.api_key'],
    metric_plugins: {},
  },
)

include_cookbook 'mackerel-agent::package'

template '/etc/mackerel-agent/mackerel-agent.conf' do
  owner 'root'
  group 'root'
  mode  '0600'
  notifies :reload, 'service[mackerel-agent]'
end

directory '/etc/mackerel-agent/mackerel-agent.conf.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/usr/share/nekomit/mackerel-agent' do
  owner 'root'
  group 'root'
  mode  '0755'
end

service 'mackerel-agent' do
  action [:enable, :start]
end
