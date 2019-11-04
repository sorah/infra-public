node.reverse_merge!(
  vault_approle_keep: {
    vault_addr: 'https://vault.nkmi.me:8200',
  },
)

include_cookbook 'vault'

directory '/etc/vault-approle-keep' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/var/lib/vault-approle-keep' do
  owner 'root'
  group 'root'
  mode  '0755'
end



remote_file '/usr/bin/vault-approle-keep-auto' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/usr/bin/vault-approle-keep-feed' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/systemd/system/vault-approle-keep@.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

remote_file '/etc/systemd/system/vault-approle-keep@.timer' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

define :vault_approle_keep, owner: 'root', group: 'root', role_id: nil, login_path: 'auth/approle/login' do
  conf = {
    vault_addr: node[:vault_approle_keep][:vault_addr],
    login_path: params[:login_path],
    owner: params[:owner],
    group: params[:group],
    role_id: params[:role_id],
  }
  file "/etc/vault-approle-keep/#{params[:name]}.json" do
    content "#{conf.to_json}\n"
    owner params[:owner]
    group params[:group]
    mode  '0640'
  end

  service "vault-approle-keep@#{params[:name]}.timer" do
    action [:enable, :start]
  end
end

