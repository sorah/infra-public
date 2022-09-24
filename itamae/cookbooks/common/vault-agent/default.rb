node.reverse_merge!(
  vault: {
    agent: {
      config: {
        vault: {
          address: 'https://vault.nkmi.me:8200',
        },
        listener: {
          unix: {
            address: '/run/vault-agent/agent.sock',
            socket_mode: '0660',
            socket_user: 'vault',
            socket_group: 'vault',
            tls_disable: true,
          },
        },
        auto_auth: {
          method: [
            type: 'cert',
            mount_path: 'auth/cert',
            config: {
              client_cert: '/var/lib/machineidentity/identity.crt',
              client_key: '/var/lib/machineidentity/key.pem',
            },
          ],
        },
        cache: {
          use_auto_auth_token: true,
        },
        template: [*(node.dig(:vault, :agent, :templates)&.values || [])],
      },
    },
  },
)

node.reverse_merge!(
  vault: {
    agent: {
      config: {
        listener: {
          tcp: {
            address: '127.0.0.1:8200',
            tls_cert_file: '/var/lib/machineidentity/identity.crt',
            tls_key_file: '/var/lib/machineidentity/key.pem',
            tls_require_and_verify_client_cert: true,
            tls_client_ca_file: '/var/lib/machineidentity/roots.pem',
          },
        },
      },
    },
  },
) if node[:vault][:agent][:listen_tcp]

# FIXME: node.dig(:machineidentity, :units_to_reload)&.push('vault-agent.service')
node.dig(:machineidentity, :units_to_restart)&.push('vault-agent.service')

include_cookbook 'vault'

execute 'usermod -a -G machineidentity vault' do
  not_if 'id vault|grep -q machineidentity'
end

file "/etc/vault-agent.hcl" do
  content "#{node[:vault][:agent][:config].to_json}\n"
  owner 'vault'
  group 'root'
  mode  '0600'
  notifies :reload, 'service[vault-agent.service]'
end

template "/etc/systemd/system/vault-agent.service" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'vault-agent.service' do
  action [:enable, :start]
end
