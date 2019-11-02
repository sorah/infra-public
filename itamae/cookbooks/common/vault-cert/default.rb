node.reverse_merge!(
  vault_cert: {
    vault_addr: 'https://vault.nkmi.me:8200',
    token_file: '/root/.vault-token',
    certs: {
      # key: { pki:, role:, ca_file:, cert_file:, fullchain_file: key_file:, owner:, group:, mode:, sans:, cn:, ip:, units_to_reload:, units_to_restart:, threshold_days:, }
    },
  },
)

include_cookbook 'vault'

file '/etc/nkmi-vault-cert.json' do
  content "#{node[:vault_cert].to_json}\n"
  owner 'root'
  group 'root'
  mode  '0600'
end

remote_file '/usr/bin/nkmi-vault-cert' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/systemd/system/nkmi-vault-cert.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

remote_file '/etc/systemd/system/nkmi-vault-cert.timer' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'nkmi-vault-cert.timer' do
  action [:enable, :start]
end
