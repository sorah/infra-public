node.reverse_merge!(
  prometheus: {
    snmp_exporter: {
      use_cookbook_config: true,
      community: node.fetch(:snmp_community),
    },
  },
)

package 'prometheus-snmp-exporter-bin'

if node[:prometheus][:snmp_exporter][:use_cookbook_config]
  execute 'prometheus-snmp-exporter generate snmp.yml' do
    command "sed -e 's|  community: __SNMP_COMMUNITY__$|  community: #{node[:prometheus][:snmp_exporter].fetch(:community)}|' /etc/prometheus/snmp.tmpl.yml >/etc/prometheus/snmp.yml"
    action :nothing
    notifies :restart, 'service[prometheus-snmp-exporter.service]', :immediately
  end

  remote_file '/etc/prometheus/snmp.tmpl.yml' do
    owner 'root'
    group 'root'
    mode  '0644'
    notifies :run, 'execute[prometheus-snmp-exporter generate snmp.yml]', :immediately
  end


  service 'prometheus-snmp-exporter.service' do
    action [:enable, :start]
  end
end
