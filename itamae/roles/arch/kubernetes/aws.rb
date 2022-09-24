# https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt
max_ips_per_type = case node[:hocho_ec2][:instance_type]
                    when /^t3a?\.(?:nano|micro)$/
                      2*2
                    when /^t3a?\.(?:small)$/
                      2*4
                    when /^t3a?\.(?:medium)$/
                      3*6
                    when /^t3a?\.(?:large)$/
                      3*12
                    when /^t3a?\.(?:2?xlarge)$/
                      4*15
                    else
                      2
                    end

node.reverse_merge!(
  kubernetes: {
    max_pods_per_node: max_ips_per_type*8,
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
