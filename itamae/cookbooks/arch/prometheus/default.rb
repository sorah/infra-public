node.reverse_merge!(
  prometheus: {
  },
)

package 'prometheus'

directory '/etc/prometheus' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/systemd/system/prometheus.service.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end
