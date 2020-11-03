node.reverse_merge!(
  loopback: {
    #addresses: [],
  },
)

template '/etc/systemd/network/loopback.network' do
  owner 'root'
  group 'root'
  mode  '0644'
end
