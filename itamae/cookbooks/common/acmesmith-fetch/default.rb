node.reverse_merge!(
  acmesmith_fetch: {
    common_names: {}, # owner: group:
    store_path: '/etc/ssl/self',
    aws_use_access_key: false,
    aws_use_vault: false,
    aws_role_arn: 'app-acmesmith-fetch',
    s3_region: 'ap-northeast-1',
    s3_bucket: 'sorah-acmesmith',
    s3_prefix: 'private-prod/',
    units_to_reload: %w(),
    units_to_restart: %w(),
    cert_passphrase: node[:secrets][:acmesmith_cert_passphrase],
  },
)

case
when node[:acmesmith_fetch][:aws_use_access_key] && !(node[:acmesmith_fetch][:aws_access_key_id] && node[:acmesmith_fetch][:aws_secret_access_key])
  node[:acmesmith_fetch][:aws_access_key_id] = node[:secrets][:'aws.acmesmith-fetch.id']
  node[:acmesmith_fetch][:aws_secret_access_key] = node[:secrets][:'aws.acmesmith-fetch.key']
when node[:acmesmith_fetch][:aws_use_vault]
  # do nothing
when !node[:hocho_ec2]
  include_cookbook 'needroleshere'
  needroleshere_binding 'nkmi-acmesmith-fetch' do
    mode 'ecs-relative-query'
    role_arn node[:acmesmith_fetch].fetch(:aws_role_arn)
  end
end

include_cookbook 'prometheus-textfile-certificate'
include_cookbook 'vault-aws-creds'
include_cookbook 'aws-sdk-ruby'

remote_file '/usr/bin/nkmi-acmesmith-fetch' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/systemd/system/nkmi-acmesmith-fetch.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

remote_file '/etc/systemd/system/nkmi-acmesmith-fetch.timer' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

execute "nkmi-acmesmith-fetch" do
  command 'systemctl start nkmi-acmesmith-fetch.service'
  action :nothing
end

file '/etc/nkmi-acmesmith-fetch.json' do
  content "#{JSON.pretty_generate(node[:acmesmith_fetch])}\n"
  owner 'root'
  group 'root'
  mode  '0600'
  notifies :run, 'execute[nkmi-acmesmith-fetch]'
end

directory node[:acmesmith_fetch].fetch(:store_path) do
  owner 'root'
  group 'root'
  mode  '0755'
end

service 'nkmi-acmesmith-fetch.timer' do
  action [:enable, :start]
end
