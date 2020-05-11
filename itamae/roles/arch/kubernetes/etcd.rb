node[:vault_cert][:certs][:etcd_server] = node[:vault_cert][:certs][:etcd].merge(
  role: 'master',
  trust_ca_file: '/etc/ssl/self/k8s-etcd-server/trust.pem',
  ca_file: '/etc/ssl/self/k8s-etcd-server/ca.pem',
  cert_file: '/etc/ssl/self/k8s-etcd-server/cert.pem',
  fullchain_file: '/etc/ssl/self/k8s-etcd-server/fullchain.pem',
  key_file: '/etc/ssl/self/k8s-etcd-server/key.pem',
  cn: "#{node[:hostname]}.aperture.k8s-etcd.nkmi.me",
  sans: ["aperture.k8s-etcd.nkmi.me"],
  owner: 'etcd',
  group: 'etcd',
)

node[:vault_cert][:certs][:etcd_kube] = node[:vault_cert][:certs][:etcd].merge(
  role: 'master',
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
        listen_peer_urls: "https://0.0.0.0:12380",
        initial_advertise_peer_urls: "https://#{node[:hostname]}.aperture.k8s-etcd.nkmi.me:12380",
        listen_client_urls: "https://0.0.0.0:12379",
        advertise_client_urls: "https://#{node[:hostname]}.aperture.k8s-etcd.nkmi.me:12379",
        discovery_srv: 'aperture.k8s-etcd.nkmi.me',
        initial_cluster_token: 'k8s-aperture-etcd',
        initial_cluster_state: 'new', # 'existing',
        cert_file: '/etc/ssl/self/k8s-etcd-server/cert.pem',
        key_file: '/etc/ssl/self/k8s-etcd-server/key.pem',
        client_cert_auth: 'true',
        trusted_ca_file: '/etc/ssl/self/k8s-etcd-server/trust.pem',
        peer_cert_file: '/etc/ssl/self/k8s-etcd-server/cert.pem',
        peer_key_file: '/etc/ssl/self/k8s-etcd-server/key.pem',
        peer_client_cert_auth: 'true',
        peer_trusted_ca_file: '/etc/ssl/self/k8s-etcd-server/trust.pem',
        peer_cert_allowed_cn: 'aperture.k8s-etcd.nkmi.me',
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
