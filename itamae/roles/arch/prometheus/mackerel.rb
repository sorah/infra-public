file '/etc/mackerel-agent/mackerel-agent.conf.d/prometheus.conf' do
  content <<-EOF
[plugin.checks.prometheus-readiness]
command = ["check-http", "-u", "http://localhost:9090/-/ready"]
  EOF

  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[mackerel-agent]'
end

file '/etc/mackerel-agent/mackerel-agent.conf.d/alertmanager.conf' do
  content <<-EOF
[plugin.checks.alertmanager-readiness]
command = ["check-http", "-u", "http://localhost:9093/-/ready"]
  EOF

  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[mackerel-agent]'
end
