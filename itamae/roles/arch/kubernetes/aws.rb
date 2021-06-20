# https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt
max_pods_per_node = case node[:hocho_ec2][:instance_type]
                    when /^t3a?\.(?:nano|micro)$/
                      4
                    when 't3a.small'
                      8
                    when 't3.small'
                      11
                    when /^t3a?\.(?:medium)$/
                      17
                    when /^t3a?\.(?:large)$/
                      35
                    when /^t3a?\.(?:2?xlarge)$/
                      58
                    else
                      4
                    end

node.reverse_merge!(
  kubernetes: {
    max_pods_per_node: max_pods_per_node,
  },
)

if node[:packer]
  template '/usr/bin/nkmi-kube-autoscaling-init' do
    owner 'root'
    group 'root'
    mode  '0755'
  end

  template '/etc/systemd/system/nkmi-kube-autoscaling-init.service' do
    owner 'root'
    group 'root'
    mode  '0644'
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
  end

  service 'nkmi-kube-autoscaling-init.service' do
    action [:enable]
  end
end
