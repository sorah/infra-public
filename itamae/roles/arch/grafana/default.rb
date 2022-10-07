node.reverse_merge!(
  grafana: {
    domain: 'grafana.nkmi.me',
    secret_key: node[:secrets].fetch(:'grafana.secret_key'),
    admin_password: node[:secrets].fetch(:'grafana.admin_password'),
    oauth_client_id: node[:secrets].fetch(:'grafana.oauth_client_id'),
    oauth_client_secret: node[:secrets].fetch(:'grafana.oauth_client_secret'),
    scopes: 'openid email name',
    auth_url: node[:secrets].fetch(:'grafana.oauth_auth_url'), # https://login.microsoftonline.com/DIR_ID/oauth2/authorize
    token_url: node[:secrets].fetch(:'grafana.oauth_token_url'), # https://login.microsoftonline.com/DIR_ID/oauth2/token
  },
)
include_role 'base'
include_cookbook 'mnt-vol'
include_cookbook 'grafana'

directory '/mnt/vol/grafana-data' do
  owner 'grafana'
  group 'grafana'
  mode  '0755'
end

template '/etc/grafana.ini' do
  owner 'root'
  group 'grafana'
  mode  '0640'
  notifies :restart, 'service[grafana]'
end

service 'grafana' do
  action [:enable, :start]
end

include_role 'grafana::envoy_sidecar'
