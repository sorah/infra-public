include_cookbook 'lvm'
include_cookbook 'topolvm'

directory '/etc/topolvm' do
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/etc/topolvm/lvmd.yaml' do
  content "#{node[:kubernetes][:topolvm].fetch(:lvmd).to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

service 'topolvm-lvmd.service' do
  action [:enable]
end
