node.reverse_merge!(
  nftables: {
  },
)

package 'nftables'

execute 'nft -f /etc/nftables.conf' do
  command 'nft -f /etc/nftables.conf'
  action :nothing
end

if node[:nftables][:config_file]
  rule_source = node[:nftables][:config_file]

  template "/etc/nftables.conf" do
    source "templates/etc/nftables.#{rule_source}.conf"
    owner 'root'
    group 'wheel'
    mode  '0640'
  end
end

service 'nftables' do
  action :enable
end

