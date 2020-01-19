node.reverse_merge!(
  bgp_anycast: {
    ospf: {
      areas: {
        # id: { interfaces: [] }
      },
    },
    neighbors: {
      bird: {
        asn: 4200000000,
        local: '127.0.0.1',
        address: '127.0.0.1',
      },
    },
  },
)

include_cookbook 'bird'
template "/etc/bird/bird.conf" do
  source "templates/etc/bird/bird-ospf.conf"
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[bird]'
end

service "bird" do
  action [:enable, :start]
end
