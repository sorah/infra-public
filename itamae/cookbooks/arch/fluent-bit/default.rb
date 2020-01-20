node.reverse_merge!(
  fluent_bit: {
    read_only_paths: %w(),
  },
)

package 'fluent-bit'

directory '/etc/systemd/system/fluent-bit.service.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end

template '/etc/systemd/system/fluent-bit.service.d/sandbox.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end
