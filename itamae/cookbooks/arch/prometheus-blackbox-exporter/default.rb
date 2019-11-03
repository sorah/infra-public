node.reverse_merge!(
  prometheus: {
    blackbox_exporter: {
      config: {
      },
    },
  },
)

package 'prometheus-blackbox-exporter'

file "/etc/prometheus/blackbox.yml" do
  content "#{node[:prometheus][:blackbox_exporter].fetch(:config).to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, "service[prometheus-blackbox-exporter.service]", :immediately
end

service 'prometheus-blackbox-exporter.service' do
  action [:enable, :start]
end
