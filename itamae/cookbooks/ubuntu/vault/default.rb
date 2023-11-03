# https://www.hashicorp.com/official-packaging-guide
include_cookbook 'apt-source-hashicorp'

# https://github.com/hashicorp/vault/blob/main/.release/linux/postinst
# Disable automatic key generation
directory '/opt/vault' do
  owner 'root'
  group 'root'
  mode  '0644'
end

directory '/opt/vault/tls' do
  owner 'root'
  group 'root'
  mode  '0700'
end

file '/opt/vault/tls/tls.crt' do
  content "\n"
  owner 'root'
  group 'root'
  mode  '0600'
end

file '/opt/vault/tls/tls.key' do
  content "\n"
  owner 'root'
  group 'root'
  mode  '0600'
end

package 'vault'
