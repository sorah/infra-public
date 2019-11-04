node.reverse_merge!(
  prometheus: {
    unbound_exporter: {
    },
  },
)

node[:prometheus][:exporter_proxy][:exporters][:unbound_exporter] = {path: '/unbound_exporter/metrics', url: 'http://localhost:9167/metrics'}

package 'prometheus-unbound-exporter-git'

service 'prometheus-unbound-exporter.service' do
  action [:enable, :start]
end
