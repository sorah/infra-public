node.reverse_merge!(
  fuse: {
    user_allow_other: true,
  },

  cloud_sql_proxy: {
    dir: '/mnt/cloud-sql-proxy',
    credential_file: '/var/lib/cloud-sql-proxy/credentials.json',
  },
)

user 'cloudsql' do
  system_user true
end

# FIXME: GCE instace metadata

include_cookbook 'fuse'
package 'cloud-sql-proxy-bin'

directory '/mnt/cloud-sql-proxy' do
  owner 'cloudsql'
  group 'cloudsql'
  mode  '0755'
end

template '/etc/systemd/system/cloud-sql-proxy.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end
