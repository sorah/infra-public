node.reverse_merge!(
  prometheus: {
    remo_e_exporter: {
      oauth_token: node[:secrets].fetch(:remo_exporter_oauth_token),
      cache_invalidation_seconds: 30,
    },
  },
)

package 'prometheus-remo-e-exporter'

file '/etc/conf.d/prometheus-remo-e-exporter' do
  content "OAUTH_TOKEN=#{node[:prometheus][:remo_e_exporter][:oauth_token]}\nCACHE_INVALIDATION_SECONDS=#{node[:prometheus][:remo_e_exporter][:cache_invalidation_seconds]}\n"
  owner 'root'
  group 'root'
  mode  '0600'
  notifies :restart, 'service[prometheus-remo-e-exporter]'
end

service 'prometheus-remo-e-exporter' do
  action [:enable, :start]
end
