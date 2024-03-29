node.reverse_merge!(
  prometheus: {
    tsdb: {
      path: '/mnt/vol/prometheus-data',
      retention_time: '20d',
      min_block_duration: '2h',
      max_block_duration: '2h',
    },
    grafana: true, # XXX:
  },
)

include_role 'prometheus::config'

include_role 'base'

unless node[:hocho_ec2]
  include_cookbook 'needroleshere'
  needroleshere_binding 'thanos-sidecar' do
    mode 'ecs-relative'
    role_arn 'ec2-prometheus'
  end
  needroleshere_binding 'grafana' do
    mode 'ecs-full'
    role_arn 'ec2-prometheus'
  end
  needroleshere_binding 'prometheus' do
    mode 'ecs-full'
    role_arn 'ec2-prometheus'
  end
end

include_cookbook 'mnt-vol'
include_cookbook 'prometheus'

include_recipe './alertmanager.rb'
include_recipe './snmp.rb'
include_recipe './blackbox.rb'

include_recipe './auth.rb'

include_recipe './mackerel.rb' if node[:base][:mackerel_agent]

include_role 'prometheus::custom'

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

template '/etc/systemd/system/prometheus.service.d/exec.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'prometheus.service' do
  action [:enable, :start]
end

include_role 'grafana' if node[:prometheus][:grafana] # XXX:
