node.reverse_merge!(
  prometheus: {
  },
)

include_role 'prometheus::config'

include_role 'base'
include_cookbook 'mnt-vol'
include_cookbook 'prometheus'

include_recipe './alertmanager.rb'
include_recipe './snmp.rb'
include_recipe './blackbox.rb'

directory '/mnt/vol/prometheus-data' do
  owner 'prometheus'
  group 'prometheus'
  mode  '0755'
end

file '/etc/prometheus/prometheus.yml' do
  content "#{node[:prometheus][:config].to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[prometheus.service]'
end

service 'prometheus.service' do
  action [:enable, :start]
end

include_role 'grafana' # XXX:
