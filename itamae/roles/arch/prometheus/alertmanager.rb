include_role 'prometheus::alertmanager-config'

include_cookbook 'prometheus-alertmanager'

directory '/mnt/vol/alertmanager' do
  owner 'prometheus'
  group 'prometheus'
  mode  '0755'
end

file "/etc/alertmanager/alertmanager.yml" do
  content "#{node[:prometheus][:alertmanager].fetch(:config).to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[alertmanager.service]", :immediately
end

service "alertmanager.service" do
  action [:enable, :start]
end
