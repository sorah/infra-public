# NOTE: the recipes in this cookbook expects kubeadm-built cluster.
# TODO: manage static pods in recipes

include_role 'kubetest::override'

node.reverse_merge!(
  kubernetes: {
    master: false,
    cluster_name: 'aperture',
    master_vault_role_id: node[:secrets][:'vault_approle.role_id.k8s_aperture_master'],
    node_vault_role_id: node[:secrets][:'vault_approle.role_id.k8s_aperture_node'],
  },
)
# include_role 'kubetest::master-prelude' if node[:kubernetes][:master]
node.reverse_merge!(
  docker: {
    daemon_config: {
      'exec-opts' => ["native.cgroupdriver=systemd"],
    },
  },
  vault_cert: {
    env_file: '/var/lib/vault-approle-keep/kubernetes',
    certs: {
      etcd: {
        trust_pkis: %w(pki/k8s-aperture-etcd/g1),
        pki: 'pki/k8s-aperture-etcd/g1',
        role: 'node',
        trust_ca_file: '/etc/ssl/self/k8s-etcd/trust.pem',
        ca_file: '/etc/ssl/self/k8s-etcd/ca.pem',
        cert_file: '/etc/ssl/self/k8s-etcd/cert.pem',
        fullchain_file: '/etc/ssl/self/k8s-etcd/fullchain.pem',
        key_file: '/etc/ssl/self/k8s-etcd/key.pem',
        owner: 'root',
        group: 'root',
        cn: "k8s-node",
        sans: ["#{node[:hostname]}.k8s-node"],
        units_to_reload: %w(),
        threshold_days: 7,
      },
    },
  },
)

include_role 'base'
include_role 'kubetest::master' if node[:kubernetes][:master]

directory '/etc/kubernetes' do
  owner 'root'
  group 'root'
  mode  '0755'
end

##

include_cookbook 'vault-approle-keep'
include_cookbook 'vault-cert'

directory '/etc/ssl/self/k8s-etcd' do
  owner 'root'
  group 'root'
  mode  '0755'
end

vault_approle_keep 'kubernetes' do
  role_id node[:kubernetes][:master] ? node[:kubernetes][:master_vault_role_id] : node[:kubernetes][:node_vault_role_id]
end

##

include_role 'kubetest::routing'
include_role 'kubetest::logging'

##

include_cookbook 'docker'
package 'kubernetes-bin'
package 'ebtables'
package 'ethtool'

directory '/etc/kubernetes/apiserver' do
  owner 'root'
  group 'root'
  mode  '0755'
end

%w(
  /etc/kubernetes/config
  /etc/kubernetes/controller-manager
  /etc/kubernetes/kubelet
  /etc/kubernetes/proxy
  /etc/kubernetes/scheduler
).each do |_|
  file _ do
    action :delete
  end
end

##

template "/etc/systemd/system/kubelet.service" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'kubelet' do
  action [:enable]
end
