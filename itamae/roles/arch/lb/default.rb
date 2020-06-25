node.reverse_merge!(
  lb: {
    services: {
      # name: {
      #   address_v4: 
      #   address_v6: 
      #   port: 
      #   backends: [
      #     { v4: '', v6: '', port: 80, weight: 1 },
      #   ],
      #   check: {
      #     retry: ,
      #     interval: ,
      #     http: {
      #       ssl: ,
      #       path: ,
      #       status_code: 200,
      #       virtualhost: '',
      #     },
      #     tcp: false,
      #   },
      # },
    },
  },
)

include_cookbook 'ipvs'
##

directory '/run/nkmi-lb' do
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/etc/tmpfiles.d/nkmi-lb.conf' do
  content "d /run/nkmi-lb 0755 root root - -\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

remote_file "/etc/sysctl.d/90-nkmi-lb.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[sysctl -p /etc/sysctl.d/90-nkmi-lb.conf]'
end

execute 'sysctl -p /etc/sysctl.d/90-nkmi-lb.conf' do
  action :nothing
end

##
include_cookbook 'keepalived'

template '/etc/keepalived/keepalived.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[keepalived.service]'
end

service 'keepalived.service' do
  action [:enable, :start]
end

##
include_cookbook 'bird'


