subnet_ip = node[:hocho_subnet][:cidr_block].split(?/,2)[0].split(?.).map(&:to_i)
subnet_ip[-1] += 1
router = subnet_ip.join(?.)

local_vpc_routes = node[:hocho_vpc][:cidr_block_association_set].map{ |_| _[:cidr_block] }.map do |vpc_cidr|
  "#{vpc_cidr} via #{router}"
end

node[:bgp_anycast][:router_id] = node.dig(:hocho_ec2, :private_ip_address)

##
# Since inter-region VPC peering (PCX) enforces src/dst address check,
# We use VXLAN overlay to route VPC-outside traffic. (named anypeer)
include_cookbook 'ec2-vxlan'
include_cookbook 'bird'

template "/etc/bird/bird.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  variables local_vpc_routes: local_vpc_routes
  notifies :run, 'execute[systemctl try-reload-or-restart bird.service]'
end

service "bird" do
  action [:enable, :start]
end
