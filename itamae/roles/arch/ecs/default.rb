node.reverse_merge!(
  mnt_vol: {
    fstype: 'btrfs',
  },
  docker: {
    daemon_config: {
      'storage-driver' => 'btrfs',
      'data-root' => '/mnt/vol/docker',
      'log-driver' => 'fluentd',
      'log-opts' => {
        labels: %w(
          com.amazonaws.ecs.task-arn
          com.amazonaws.ecs.container-name
          com.amazonaws.ecs.task-definition-family
          com.amazonaws.ecs.task-definition-version
        ).join(?,),
        tag: 'ecs.{{.ID}}',
        'fluentd-sub-second-precision' => 'true',
      },
    },
  },
  ecs: {
    env: {
      ECS_VERSION: 'v1.36.1',
      ECS_AVAILABLE_LOGGING_DRIVERS: '[\"fluentd\",\"none\"]',
      ECS_DATADIR: '/data',
      ECS_ENABLE_SPOT_INSTANCE_DRAINING: 'true',
      ECS_ENABLE_TASK_ENI: 'false',
      ECS_ENABLE_TASK_IAM_ROLE: 'true',
      ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST: 'true',
      ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION: '1h',
      ECS_LOGLEVEL: 'info',
    },
    fluentd: {
    #  papertrail_host: nil,
    #  papertrail_port: nil,
    },
  },
)
node[:ecs][:env][:ECS_CLUSTER] = node[:hocho_ec2][:tags]['Cluster'] unless node[:packer]

include_role 'ecs::custom'

include_role 'base'

node[:prometheus][:exporter_proxy][:exporters][:cadvisor] = {path: '/cadvisor/metrics', url: 'http://localhost:9103/metrics'}

include_cookbook 'mnt-vol'
include_cookbook 'docker'

# when it available, cloud-init starts dhclient where a unwanted behavior
# package 'dhclient' # XXX: separate cookbook
#
file '/etc/sysctl.d/99-ecs.conf' do
  content "net.ipv4.conf.all.route_localnet=1\n"
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[sysctl -p /etc/sysctl.d/99-ecs.conf]'
end

execute 'sysctl -p /etc/sysctl.d/99-ecs.conf' do
  action :nothing
end

file '/etc/modprobe.d/br_netfilter.conf' do
  content "install br_netfilter\n"
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[modprobe br_netfilter]'
end

execute 'modprobe br_netfilter' do
  action :nothing
end

##

include_cookbook 'fluentd'
gem_package 'fluent-plugin-papertrail'  

template "/etc/fluent/fluent.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
end

##

remote_file '/usr/bin/amazon-ecs-agent' do
  owner 'root'
  group 'root'
  mode  '0755'
end

template "/etc/ecs.env" do
  owner 'root'
  group 'root'
  mode  '0644'
end

template '/etc/systemd/system/ecs.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

if node[:packer]
  include_recipe './ami' 
else
  service 'fluentd.service' do
    action [:enable, :start]
  end
  service 'ecs.service' do
    action [:enable, :start]
  end
end
