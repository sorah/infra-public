node.reverse_merge!(
  vault: {
    agent: {
      templates: {
        cloud_sql_proxy: {
          destination: '/var/lib/cloud-sql-proxy/credentials.vault.json',
          contents: %|{{ with secret "#{node[:cloud_sql_proxy].fetch(:vault_secret)}" }}{{ base64Decode .Data.private_key_data }}{{ end }}|,
          command: 'sudo /usr/sbin/nkmi-cloud-sql-proxy-rekey',
          command_timeout: '45s',
          perms: '0640',
        },
      },
    },
  },
)

include_cookbook 'vault-agent'


directory '/var/lib/cloud-sql-proxy' do
  owner 'cloudsql'
  group 'vault'
  mode  '0775'
end

file '/var/lib/cloud-sql-proxy/credentials.vault.json' do
  owner 'vault'
  group 'vault'
  mode  '0640'
end

template '/usr/sbin/nkmi-cloud-sql-proxy-rekey' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/sudoers.d/cloud-sql-proxy-vault-agent' do
  owner 'root'
  group 'root'
  mode  '0644'
end
