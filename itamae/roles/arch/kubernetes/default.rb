include_role 'kubernetes::override'

node.reverse_merge!(
  kubernetes: {
    master: false,
    # cluster_name: 'aperture',
    # cluster_cidr: '',
    node_cidr_mask_size: 24,
    # service_cluster_ip_range: '10.96.0.0/18',
    # apiserver_service_ip: '10.96.0.1',

    routing: true,
    pki_generations: {},

    node_name: case
               when node[:packer]
                 '__NODENAME__'
               when (node[:hocho_ec2] && node[:kubernetes][:cloud_provider] == 'aws')
                 node[:hocho_ec2].fetch(:private_dns_name) 
               else
                 node[:hostname]
               end
  },
)
# include_role 'kubetest::master-prelude' if node[:kubernetes][:master]
node.reverse_merge!(
  prometheus: {
    exporter_proxy: {
      listen: '0.0.0.0:9999', # to avoid conflict with calico node
    },
  },
  docker: {
    daemon_config: {
      'storage-driver' => 'btrfs',
      'exec-opts' => ["native.cgroupdriver=systemd"],
    },
  },
  vault_cert: {
    tls: {
      name: "k8s-#{node[:kubernetes].fetch(:cluster_name)}",
    },
    # env_file: '/var/lib/vault-approle-keep/kubernetes',
    certs: {
      node: {
        trust_pkis: %W(pki/k8s-#{node[:kubernetes].fetch(:cluster_name)}/g#{node[:kubernetes][:pki_generations].fetch(:kubernetes, 1)}),
        pki: "pki/k8s-#{node[:kubernetes].fetch(:cluster_name)}/g#{node[:kubernetes][:pki_generations].fetch(:kubernetes, 1)}",
        role: 'node',
        trust_ca_file: '/etc/ssl/self/k8s-node/trust.pem',
        ca_file: '/etc/ssl/self/k8s-node/ca.pem',
        cert_file: '/etc/ssl/self/k8s-node/cert.pem',
        fullchain_file: '/etc/ssl/self/k8s-node/fullchain.pem',
        key_file: '/etc/ssl/self/k8s-node/key.pem',
        owner: 'root',
        group: 'root',
        cn: "system:node:#{node[:kubernetes].fetch(:node_name)}",
        sans: ["system:node:#{node[:kubernetes].fetch(:node_name)}"],
        units_to_reload: %w(kubelet.service),
        threshold_days: 7,
      },
    },
  },
)

include_role 'base'
include_role 'kubernetes::aws' if node[:hocho_ec2]

include_role 'kubernetes::master' if node[:kubernetes][:master]

include_cookbook 'ipvs'
include_cookbook 'targetcli'
package 'open-iscsi'
include_cookbook 'nfs'

if node.dig(:docker, :daemon_config, 'storage-driver') == 'btrfs'
  # FIXME: Workaround for https://github.com/kubernetes/kubernetes/issues/94335
  remote_file '/etc/systemd/system/var-lib-kubelet.mount' do
    owner 'root'
    group 'root'
    mode  '0644'
    notifies :run, 'execute[systemctl daemon-reload]'
  end

  service 'var-lib-kubelet.mount' do
    action [:enable, :start]
  end
end

directory '/etc/kubernetes' do
  owner 'root'
  group 'root'
  mode  '0755'
end


##

directory '/etc/ssl/self/k8s-node' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/ssl/self/k8s-etcd' do
  owner 'root'
  group 'root'
  mode  '0755'
end

include_cookbook 'vault-approle-keep'
include_cookbook 'vault-cert'

##

include_role 'kubernetes::routing' if node[:kubernetes][:routing]
include_role 'kubernetes::logging'

##

include_cookbook 'docker'
package 'kubelet-bin'
package 'kubectl-bin'
package 'iptables'
package 'ethtool'

%w(
  /etc/kubernetes/config
  /etc/kubernetes/controller-manager
  /etc/kubernetes/kubelet
  /etc/kubernetes/proxy
  /etc/kubernetes/scheduler
  /etc/kubernetes/apiserver
).each do |_|
  execute "rm #{_.shellescape}" do
    only_if "test -f #{_.shellescape}"
  end
end

directory '/etc/kubernetes/apiserver' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/kubernetes/kubelet' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/kubernetes/manifests' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/var/lib/kubelet' do
  owner 'root'
  group 'root'
  mode  '0755'
end

##

template "/etc/systemd/system/kubelet.service" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

template "/etc/kubernetes/kubelet/kubeconfig.yaml" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[kubelet.service]'
end

template "/etc/kubernetes/kubelet/config.yaml" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[kubelet.service]'
end

##

include_role 'kubernetes::topolvm' if node[:kubernetes][:topolvm]

##

package 'cni-plugins'

directory '/opt/cni' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/opt/cni/bin' do
  owner 'root'
  group 'root'
  mode  '0755'
end

%w(
  bandwidth  bridge  dhcp  firewall  flannel  host-device  host-local  ipvlan  loopback  macvlan  portmap  ptp  sbr  static  tuning  vlan
).each do |_|
  link "/opt/cni/bin/#{_}" do
    force true
    to "/usr/lib/cni/#{_}"
  end
end

remote_file '/etc/systemd/network/10-aws-vpc-cni-k8s.link' do
  owner 'root'
  group 'root'
  mode  '0644'
end

service 'kubelet.service' do
  action [:enable]
end
