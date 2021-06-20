node.reverse_merge!(
  kubernetes: {
    logging: {
      papertrail: true,
      # papertrail_host: ,
      # papertrail_port: ,
    },
  },
)

directory "/etc/fluent" do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory "/var/lib/fluentd" do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory "/var/log/containers" do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory "/var/log/pods" do
  owner 'root'
  group 'root'
  mode  '0755'
end

template "/etc/fluent/fluent.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
end

# NOTE: fluentd runs under DaemonSet (https://github.com/nkmi/nkmi-k8s-fluentd)
