node.reverse_merge!(
  prometheus: {
    exporter_proxy: {
      listen: "0.0.0.0:9099",
      exporters: {
        node_exporter: {path: '/node_exporter/metrics', url: 'http://localhost:9100/metrics'},
      },
    },
  },
)

package 'prometheus-exporter-proxy'

template '/etc/prometheus-exporter-proxy/config.yml' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, 'service[prometheus-exporter-proxy.service]', :immediately
end

service 'prometheus-exporter-proxy.service' do
  action [:enable, :start]
end
