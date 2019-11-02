node.reverse_merge!(
  bgp_anycast: {
    # asn: 65xxx,
    # router_id:
    # services: {
    #   svc: {
    #     command: '',
    #     interval: ,
    #     timeout: ,
    #     rise: ,
    #     fall: ,
    #     ip: ,
    #     label: ,
    #     up_metric: ,
    #     down_metric: ,
    #     disabled_metric: ,
    #   }
    # }
    # neighbors: {
    #   name: {
    #     address: ,
    #     asn: 65xxx,
    #   }
    # }
  }
)

include_recipe './ec2.rb' if node[:hocho_ec2]

include_cookbook 'exabgp'

node[:bgp_anycast].fetch(:services, {}).each do |service_name, service|
  template "/etc/exabgp/healthcheck-#{service_name}.ini" do
    owner 'root'
    group 'root'
    mode  '0644'
    source 'templates/etc/exabgp/healthcheck.ini'
    variables service: service, service_name: service_name

    notifies :restart, 'service[exabgp]'
  end
end

template '/etc/exabgp/exabgp.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, 'service[exabgp]'
end

service 'exabgp' do
  action [:enable, :start]
end

