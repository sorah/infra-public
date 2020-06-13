node[:vault_cert][:tls][:name] = 'k8s-aperture-master'

include_role 'kubernetes::etcd'

node.reverse_merge!(
  kubernetes: {
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
                    secret: node[:secrets][:'kubernetes.aperture.secretbox.key1'],
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
