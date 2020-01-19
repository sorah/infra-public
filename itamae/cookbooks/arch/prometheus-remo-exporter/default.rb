node.reverse_merge!(
  prometheus: {
    remo_exporter: {
      oauth_token: node[:secrets].fetch(:remo_exporter_oauth_token),
      cache_invalidation_seconds: 30,
    },
  },
)

package 'prometheus-remo-exporter'

file '/etc/conf.d/prometheus-remo-exporter' do
  content "OAUTH_TOKEN=#{node[:prometheus][:remo_exporter][:oauth_token]}\nCACHE_INVALIDATION_SECONDS=#{node[:prometheus][:remo_exporter][:cache_invalidation_seconds]}\n"
  owner 'root'
  group 'root'
  mode  '0600'
  notifies :restart, 'service[prometheus-remo-exporter]'
end

service 'prometheus-remo-exporter' do
  action [:enable, :start]
end
