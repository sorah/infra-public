remote_file "/usr/bin/nkmi-ec2-vxlan-auto" do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file "/etc/systemd/system/nkmi-ec2-vxlan-auto.service" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

remote_file "/etc/systemd/system/nkmi-ec2-vxlan-auto.timer" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'nkmi-ec2-vxlan-auto.timer' do
  action [:enable, :start]
end
