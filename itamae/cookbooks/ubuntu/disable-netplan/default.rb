node.reverse_merge!(
  migrate_netplan: true,
)

file "/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg" do
  content "network: {config: disabled}\n"
  owner 'root'
  group 'root'
  mode  '0644'
  only_if 'test -e /etc/cloud/cloud.cfg.d'
end

if node[:migrate_netplan]
  execute "mkdir -p /etc/systemd/network && cp -pv -t /etc/systemd/network /run/systemd/network/*netplan*" do
    only_if "test -e /etc/netplan && test -d /run/systemd/network"
  end
end

execute "rm -rf /etc/netplan && netplan generate" do
  only_if "test -e /etc/netplan"
  notifies :restart, 'service[systemd-networkd]'
end
