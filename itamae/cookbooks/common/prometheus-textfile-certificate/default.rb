node.reverse_merge!(
  prometheus_textfile_certificate: {
    glob_paths: %w(
      /etc/ssl/self/*/cert.pem
      /etc/ssl/self/*/ca.pem
      /etc/ssl/self/*/trust.pem
      /etc/ssl/self/*/chain.pem
      /var/lib/machineidentity/identity.crt
      /var/lib/machineidentity/roots.pem
    ),
  },
)

file '/etc/prometheus-textfile-certificate.json' do
  content "#{node[:prometheus_textfile_certificate].to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

remote_file '/usr/bin/prometheus-textfile-certificate' do
  owner 'root'
  group 'root'
  mode  '0755'
  notifies :run, 'execute[systemctl start --no-block prometheus-textfile-certificate.service]'
end

template '/etc/systemd/system/prometheus-textfile-certificate.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

template '/etc/systemd/system/prometheus-textfile-certificate.timer' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

execute 'systemctl start --no-block prometheus-textfile-certificate.service' do
  action :nothing
end

service 'prometheus-textfile-certificate.timer' do
  action [:enable, :start]
end
