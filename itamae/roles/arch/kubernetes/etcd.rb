node[:vault_cert][:certs][:etcd_server] = {
  trust_pkis: %W(pki/k8s-#{node[:kubernetes].fetch(:cluster_name)}-etcd/g#{node[:kubernetes][:pki_generations].fetch(:etcd, 1)}),
  pki: "pki/k8s-#{node[:kubernetes].fetch(:cluster_name)}-etcd/g#{node[:kubernetes][:pki_generations].fetch(:etcd, 1)}",
  role: 'master',
  trust_ca_file: '/etc/ssl/self/k8s-etcd-server/trust.pem',
  ca_file: '/etc/ssl/self/k8s-etcd-server/ca.pem',
  cert_file: '/etc/ssl/self/k8s-etcd-server/cert.pem',
  fullchain_file: '/etc/ssl/self/k8s-etcd-server/fullchain.pem',
  key_file: '/etc/ssl/self/k8s-etcd-server/key.pem',
  cn: "#{node[:kubernetes].fetch(:cluster_name)}.k8s-etcd.nkmi.me",
  sans: ["#{node[:kubernetes].fetch(:cluster_name)}.k8s-etcd.nkmi.me", "#{node[:hostname]}.#{node[:kubernetes].fetch(:cluster_name)}.k8s-etcd.nkmi.me"],
  owner: 'etcd',
  group: 'etcd',
  units_to_reload: %w(),
  threshold_days: 7,
}

node[:vault_cert][:certs][:etcd_kube] = node[:vault_cert][:certs][:etcd_server].merge(
  role: 'kube',
  trust_ca_file: '/etc/ssl/self/k8s-etcd-kube/trust.pem',
  ca_file: '/etc/ssl/self/k8s-etcd-kube/ca.pem',
  cert_file: '/etc/ssl/self/k8s-etcd-kube/cert.pem',
  fullchain_file: '/etc/ssl/self/k8s-etcd-kube/fullchain.pem',
  key_file: '/etc/ssl/self/k8s-etcd-kube/key.pem',
  cn: "k8s-master",
  sans: ["#{node[:hostname]}.k8s-master"],
  owner: 'root',
  group: 'root',
)

node.reverse_merge!(
  etcd: {
    server: {
      env: {
        data_dir: '/mnt/vol/k8s-etcd',
        listen_peer_urls: "https://0.0.0.0:2380",
        initial_advertise_peer_urls: "https://#{node[:hostname]}.#{node[:kubernetes].fetch(:cluster_name)}.k8s-etcd.nkmi.me:2380",
        listen_client_urls: "https://0.0.0.0:2379",
        advertise_client_urls: "https://#{node[:hostname]}.#{node[:kubernetes].fetch(:cluster_name)}.k8s-etcd.nkmi.me:2379",
        discovery_srv: "#{node[:kubernetes].fetch(:cluster_name)}.k8s-etcd.nkmi.me",
        #initial_cluster_token: 'k8s-aperture-etcd',
        initial_cluster_state: 'existing', # 'new',
        cert_file: '/etc/ssl/self/k8s-etcd-server/cert.pem',
        key_file: '/etc/ssl/self/k8s-etcd-server/key.pem',
        client_cert_auth: 'true',
        trusted_ca_file: '/etc/ssl/self/k8s-etcd-server/trust.pem',
        peer_cert_file: '/etc/ssl/self/k8s-etcd-server/cert.pem',
        peer_key_file: '/etc/ssl/self/k8s-etcd-server/key.pem',
        peer_client_cert_auth: 'true',
        peer_trusted_ca_file: '/etc/ssl/self/k8s-etcd-server/trust.pem',
        peer_cert_allowed_cn: "#{node[:kubernetes].fetch(:cluster_name)}.k8s-etcd.nkmi.me",
      },
    },
  },
)

include_cookbook 'etcd'
include_cookbook 'etcd::server'

directory '/etc/ssl/self/k8s-etcd-server' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/etc/ssl/self/k8s-etcd-kube' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/mnt/vol/k8s-etcd' do
  owner 'etcd'
  group 'etcd'
  mode  '0755'
end

directory '/mnt/vol/k8s-kube' do
  owner 'etcd'
  group 'etcd'
  mode  '0755'
end

service 'etcd' do
  action [:enable]
end
