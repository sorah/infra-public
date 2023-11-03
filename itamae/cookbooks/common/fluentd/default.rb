node.reverse_merge!(
  fluentd: {
    config_path: '/etc/fluent/fluent.conf',
  },
)
if node.dig(:prometheus, :exporter_proxy)
  node[:prometheus][:exporter_proxy][:exporters][:fluentd] = {path: '/fluentd/metrics', url: 'http://localhost:24231/metrics'}
end

include_cookbook 'base-devel'

gem_package 'fluentd'
gem_package 'fluent-plugin-prometheus'
gem_package 'oj'

user 'fluentd' do
  system_user true
end

directory '/etc/fluent' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/var/lib/fluentd' do
  owner 'fluentd'
  group 'fluentd'
  mode  '0755'
end

directory '/var/lib/fluentd/buffer' do
  owner 'fluentd'
  group 'fluentd'
  mode  '0755'
end

directory '/usr/share/fluentd' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/usr/share/fluentd/plugins' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/var/log/fluentd' do
  owner 'fluentd'
  group 'fluentd'
  mode  '0755'
end

template '/etc/systemd/system/fluentd.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

directory '/etc/systemd/system/fluentd.service.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end
