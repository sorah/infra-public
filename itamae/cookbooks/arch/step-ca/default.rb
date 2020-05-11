node.reverse_merge!(
  step_ca: {
    config_json: '/etc/step-ca.json',
  },
)

include_cookbook 'step'
package 'step-ca-bin'

user 'step-ca' do
  system_user true
end

template '/etc/systemd/system/step-ca.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end
