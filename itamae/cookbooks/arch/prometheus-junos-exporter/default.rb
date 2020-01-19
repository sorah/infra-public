node.reverse_merge!(
  prometheus: {
    junos_exporter: {
      ssh_user: 'prometheus',
      ssh_key: node[:secrets].fetch(:junos_exporter_ssh_key),
      ignore_targets: true,
      config: {
        devices: [],
        features: {
          bgp: true,
          ospf: true,
          isis: false,
          nat: true,
          ldp: true,
          l2circuit: false,
          environment: true,
          routes: true,
          routing_engine: true,
          interface_diagnostic: true,
          fpc: true,
        },
      },
    },
  },
)

package 'prometheus-junos-exporter'

template '/etc/conf.d/prometheus-junos-exporter' do
  owner 'root'
  group 'root'
  mode  '0644'
end

file '/etc/prometheus-junos-exporter/config.yml' do
  content "#{node.dig(:prometheus, :junos_exporter, :config).to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

file '/etc/prometheus-junos-exporter/id_rsa' do
  content "#{node.dig(:prometheus, :junos_exporter).fetch(:ssh_key).chomp}\n"
  owner 'root'
  group 'root'
  mode  '0600'
end

service 'prometheus-junos-exporter' do
  action [:enable, :start]
end
