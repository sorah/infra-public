node.reverse_merge!(
  vault_aws_creds: {
    vault_addr: 'https://vault.nkmi.me:8200',
    # path: 
    tls: {
      path: 'auth/cert/login',
      cert_file: "/var/lib/machineidentity/identity.crt",
      key_file: "/var/lib/machineidentity/key.pem",
    },
  }
)

include_cookbook 'vault'

file "/etc/nkmi-vault-aws-creds.json" do
  content "#{node[:vault_aws_creds].to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

remote_file "/usr/bin/nkmi-vault-aws-creds" do
  owner 'root'
  group 'root'
  mode  '0755'
end

link "/usr/bin/nkmi-vault-aws-creds.rb" do
  force true
  to './nkmi-vault-aws-creds'
end
