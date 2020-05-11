node.reverse_merge!(
  step_ca: {
    config_json: '/mnt/vol/step-ca/config.json',
    password_file: '/mnt/vol/step-ca/password.txt',
    config: {
      address: ":443",
      root: [],
      federatedRoots: [],
      # crt: nil,
      # key: nil,
      dnsNames: [],
      logger: {
        format: 'json',
      },
      db: {
        type: "badger",
        dataSource: "/mnt/vol/step-ca/db",
      },
      authority: {
        provisioners: [],
      },
      tls:  {
        cipherSuites: %w(
          TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
          TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
        ),
        minVersion: 1.2,
        maxVersion: 1.2,
        renegotiation: false,
      },
    },
  },
)

include_role 'base'
include_cookbook 'step-ca'

include_role 'step-ca::logging'

directory '/mnt/vol/step-ca' do
  owner 'step-ca'
  group 'step-ca'
  mode  '0755'
end

directory '/mnt/vol/step-ca/root' do
  owner 'step-ca'
  group 'step-ca'
  mode  '0755'
end

directory '/mnt/vol/step-ca/ca' do
  owner 'step-ca'
  group 'step-ca'
  mode  '0755'
end

directory '/mnt/vol/step-ca/db' do
  owner 'step-ca'
  group 'step-ca'
  mode  '0700'
end


file node.dig(:step_ca, :config_json) do 
  content "#{node.dig(:step_ca, :config).to_json}\n"
  owner 'step-ca'
  group 'step-ca'
  mode  '0600'
  notifies :reload, 'service[step-ca.service]'
end

service "step-ca.service" do
  action [:enable, :start]
end
