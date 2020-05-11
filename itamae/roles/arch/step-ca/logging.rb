node.reverse_merge!(
  step_ca: {
    logging: {
      srv_hostname: 'fluentd.nkmi.me',
    },
  },
)

include_cookbook 'fluentd'

template "/etc/fluent/fluent.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
end

file '/var/log/step-ca.log' do
  owner 'root'
  group 'fluentd'
  mode  '0640'
end

service 'fluentd.service' do
  action [:enable, :start]
end
