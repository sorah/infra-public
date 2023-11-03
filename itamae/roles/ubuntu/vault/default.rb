include_cookbook 'vault'

node.reverse_merge!(
  acmesmith_fetch: {
    common_names: {
      :"vault.nkmi.me" => {owner: 'vault', group: 'vault'},
    },
    units_to_reload: %w(vault.service)
  },
  vault: {
    caps: true,
    server: {
      config: {
        listener: {
          tcp: {
            address: "0.0.0.0:8200",
            tls_cert_file: "/etc/ssl/self/vault.nkmi.me/fullchain.pem",
            tls_key_file: "/etc/ssl/self/vault.nkmi.me/key.pem",
          },
        },
        storage: {
          s3: {
            bucket: 'nkmi-vault',
            region: 'ap-northeast-1',
          },
        },
        telemetry: {
          prometheus_retention_time: "2m",
          disable_hostname: true,
        },
      },
    },
  }
)

include_role 'base'
include_cookbook 'nftables-metadata-protection'
include_cookbook 'vault'

include_cookbook 'acmesmith-fetch'

file "/etc/vault.d/vault.hcl" do
  content "#{node[:vault][:server][:config].to_json}\n"
  owner 'vault'
  group 'vault'
  mode  '0600'
end

directory "/var/log/vault" do
  owner 'vault'
  group 'vault'
  mode  '0755'
end

service "vault.service" do
  action [:enable, :start]
end
