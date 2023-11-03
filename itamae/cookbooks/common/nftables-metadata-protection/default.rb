include_cookbook 'nftables'

template '/etc/nftables.conf' do
  owner 'root'
  group 'wheel'
  mode  '0640'
  notifies :run, 'execute[nft -f /etc/nftables.conf]'
end
