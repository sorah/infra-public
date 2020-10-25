node.reverse_merge!(
  vault_cert: {
    tls: {
      name: "prometheus",
    },
    certs: {
   },
  },
)

include_cookbook 'vault-cert'
include_cookbook 'vault-agent'

execute 'usermod -a -G machineidentity prometheus' do
  not_if 'id prometheus|grep -q machineidentity'
end
