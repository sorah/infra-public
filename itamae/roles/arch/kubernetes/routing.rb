# Routing with coil
node.reverse_merge!(
  kubernetes: {
    routing: {
      ospf: nil,
      bgp_peers: {},
      # ospf: {
      #   areas: {
      #     id => { 
      #       interfaces: {
      #         interface_name => {
      #           cost: 500,
      #           hello: 2,
      #           dead: 6,
      #         },
      #       },
      #     },
      #   },
      # },
    },
  },
)

include_cookbook 'bird'

template "/etc/bird/bird.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[bird]'
end

service "bird" do
  action [:enable, :start]
end



