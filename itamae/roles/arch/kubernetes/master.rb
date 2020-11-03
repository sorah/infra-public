node[:vault_cert][:tls][:name] = "k8s-#{node[:kubernetes].fetch(:cluster_name)}-master"

node[:vault_cert][:certs][:apiserver] = node[:vault_cert][:certs][:node].merge(
  role: 'apiserver',
  trust_ca_file: '/etc/ssl/self/k8s-apiserver/trust.pem',
  ca_file: '/etc/ssl/self/k8s-apiserver/ca.pem',
  cert_file: '/etc/ssl/self/k8s-apiserver/cert.pem',
  fullchain_file: '/etc/ssl/self/k8s-apiserver/fullchain.pem',
  key_file: '/etc/ssl/self/k8s-apiserver/key.pem',
  cn: "#{node[:kubernetes].fetch(:cluster_name)}.k8s.nkmi.me",
  sans: [
    "#{node[:kubernetes].fetch(:cluster_name)}.k8s.nkmi.me",
    "#{node[:kubernetes].fetch(:cluster_name)}.k8s-control.nkmi.me",
    "#{node[:hostname]}.#{node[:kubernetes].fetch(:cluster_name)}.k8s-control.nkmi.me",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.#{node[:kubernetes].fetch(:cluster_name)}.k.nkmi.me",
    "kubernetes.default.svc.cluster.k.nkmi.me",
  ],
  ip: true,
  ip_sans: [node[:kubernetes].fetch(:apiserver_service_ip)],
)
node[:vault_cert][:certs][:apiserver_kubelet_client] = node[:vault_cert][:certs][:node].merge(
  role: 'apiserver-kubelet-client',
  trust_ca_file: '/etc/ssl/self/k8s-apiserver-kubelet-client/trust.pem',
  ca_file: '/etc/ssl/self/k8s-apiserver-kubelet-client/ca.pem',
  cert_file: '/etc/ssl/self/k8s-apiserver-kubelet-client/cert.pem',
  fullchain_file: '/etc/ssl/self/k8s-apiserver-kubelet-client/fullchain.pem',
  key_file: '/etc/ssl/self/k8s-apiserver-kubelet-client/key.pem',
  cn: "kube-apiserver-kubelet-client",
  sans: ["kube-apiserver-kubelet-client"],
)
node[:vault_cert][:certs][:kube_controller_manager] = node[:vault_cert][:certs][:node].merge(
  role: 'kube-controller-manager',
  trust_ca_file: '/etc/ssl/self/k8s-kube-controller-manager/trust.pem',
  ca_file: '/etc/ssl/self/k8s-kube-controller-manager/ca.pem',
  cert_file: '/etc/ssl/self/k8s-kube-controller-manager/cert.pem',
  fullchain_file: '/etc/ssl/self/k8s-kube-controller-manager/fullchain.pem',
  key_file: '/etc/ssl/self/k8s-kube-controller-manager/key.pem',
  cn: "system:kube-controller-manager",
  sans: ["system:kube-controller-manager", "kube-controller-manager.kube-system.svc.#{node[:kubernetes].fetch(:cluster_name)}.k.nkmi.me"],
)
node[:vault_cert][:certs][:kube_scheduler] = node[:vault_cert][:certs][:node].merge(
  role: 'kube-scheduler',
  trust_ca_file: '/etc/ssl/self/k8s-kube-scheduler/trust.pem',
  ca_file: '/etc/ssl/self/k8s-kube-scheduler/ca.pem',
  cert_file: '/etc/ssl/self/k8s-kube-scheduler/cert.pem',
  fullchain_file: '/etc/ssl/self/k8s-kube-scheduler/fullchain.pem',
  key_file: '/etc/ssl/self/k8s-kube-scheduler/key.pem',
  cn: "system:kube-scheduler",
  sans: ["system:kube-scheduler", "kube-scheduler.kube-system.svc.#{node[:kubernetes].fetch(:cluster_name)}.k.nkmi.me"],
)

node[:vault_cert][:certs][:frontproxy_client] = {
  trust_pkis: %W(pki/k8s-#{node[:kubernetes].fetch(:cluster_name)}-frontproxy/g1),
  pki: "pki/k8s-#{node[:kubernetes].fetch(:cluster_name)}-frontproxy/g1",
  role: 'master',
  trust_ca_file: '/etc/ssl/self/k8s-frontproxy/trust.pem',
  ca_file: '/etc/ssl/self/k8s-frontproxy/ca.pem',
  cert_file: '/etc/ssl/self/k8s-frontproxy/cert.pem',
  fullchain_file: '/etc/ssl/self/k8s-frontproxy/fullchain.pem',
  key_file: '/etc/ssl/self/k8s-frontproxy/key.pem',
  cn: "aperture.k8s-frontproxy.nkmi.me",
  sans: ["#{node[:hostname]}.aperture.k8s-frontproxy.nkmi.me"],
  owner: 'root',
  group: 'root',
  units_to_reload: %w(),
  threshold_days: 7,
}



include_role 'kubernetes::etcd'

node.reverse_merge!(
  kubernetes: {
    version: '1.19.3',
    scheduler: {
      # topolvm: false
    },
    apiserver: {
      # oidc_client_id: ,
      # oidc_issuer_url: ,
      # service_account_key: "---BEGIN...",
      # service_account_signing_key: node[:secrets].fetch(:"kubernetes.#{node[:kubernetes].fetch(:cluster_name)}.service_account_signing_key"),
      # service_account_issuer: "https://...",
    },
    encryption: {
      resources: [
        {
          resources: %w(secrets),
          providers: [
            {
              secretbox: {
                keys: [
                  {
                    name: 'key1',
                    secret: node[:secrets][:"kubernetes.#{node[:kubernetes].fetch(:cluster_name)}.secretbox.key1"],
                  },
                ]
              },
            },
            { identity: {} },
          ],
        },
      ],
    },
  },
)

directory '/etc/ssl/self/k8s-apiserver' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/ssl/self/k8s-apiserver-kubelet-client' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/ssl/self/k8s-kube-controller-manager' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/ssl/self/k8s-kube-scheduler' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/ssl/self/k8s-frontproxy' do
  owner 'root'
  group 'root'
  mode  '0755'
end

###

directory '/etc/kubernetes/apiserver' do
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/etc/kubernetes/apiserver/encryption.yaml' do
  content({
    apiVersion: 'apiserver.config.k8s.io/v1',
    kind: 'EncryptionConfiguration',
  }.merge(node[:kubernetes].fetch(:encryption)).to_json + "\n")
  owner 'root'
  group 'root'
  mode  '0600'
end

file '/etc/kubernetes/apiserver/sa.pub' do
  content "#{node[:kubernetes][:apiserver].fetch(:service_account_key)}\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

file '/etc/kubernetes/apiserver/sa.key' do
  content "#{node[:kubernetes][:apiserver].fetch(:service_account_signing_key)}\n"
  owner 'root'
  group 'root'
  mode  '0600'
end

template '/etc/kubernetes/manifests/kube-apiserver.yaml' do
  owner 'root'
  group 'root'
  mode  '0644'
end


###

directory '/etc/kubernetes/scheduler' do
  owner 'root'
  group 'root'
  mode  '0755'
end

template "/etc/kubernetes/scheduler/scheduler.yaml" do
  owner 'root'
  group 'root'
  mode  '0644'
end

template "/etc/kubernetes/scheduler/kubeconfig.yaml" do
  owner 'root'
  group 'root'
  mode  '0644'
end

template '/etc/kubernetes/manifests/kube-scheduler.yaml' do
  owner 'root'
  group 'root'
  mode  '0644'
end

###

directory '/etc/kubernetes/controller-manager' do
  owner 'root'
  group 'root'
  mode  '0755'
end

template "/etc/kubernetes/controller-manager/kubeconfig.yaml" do
  owner 'root'
  group 'root'
  mode  '0644'
end

template '/etc/kubernetes/manifests/kube-controller-manager.yaml' do
  owner 'root'
  group 'root'
  mode  '0644'
end
