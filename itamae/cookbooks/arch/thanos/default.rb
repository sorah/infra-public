package 'thanos'

directory '/etc/systemd/system/thanos-sidecar.service.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end
