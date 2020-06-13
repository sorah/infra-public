## use with sorah/hocho-jwt
# maintains the following files with step-ca:
# - /var/lib/machineidentity/roots.pem
# - /var/lib/machineidentity/identity.crt
# - /var/lib/machineidentity/key.pem

node.reverse_merge!(
  machineidentity: {
    # ca_url;
    # fingerprint:
    token: node.dig(:hocho_jwt, :token),
    common_name: node.dig(:hocho_jwt, :payload, :sub),
    units_to_reload: [],
    units_to_restart: [],
  },
)


include_cookbook 'prometheus-textfile-certificate'
include_cookbook 'step'

group 'machineidentity' do
  gid 196
end

user 'machineidentity' do
  gid 196
end

directory '/var/lib/machineidentity' do
  owner 'machineidentity'
  group 'machineidentity'
  mode  '0755'
end

directory '/var/lib/machineidentity/step' do
  owner 'machineidentity'
  group 'machineidentity'
  mode  '0700'
end

directory '/var/lib/machineidentity/stage' do
  owner 'machineidentity'
  group 'machineidentity'
  mode  '0700'
end


template "/usr/bin/machineidentity-bootstrap" do
  user  "root"
  group "root"
  mode  "0755"
end

template "/usr/bin/machineidentity-renewal" do
  user  "root"
  group "root"
  mode  "0755"
end

template "/usr/bin/machineidentity-renewal-notify" do
  user  "root"
  group "root"
  mode  "0755"
end

template "/etc/sudoers.d/machineidentity" do
  user  "root"
  group "root"
  mode  "0600"
end

template "/etc/systemd/system/machineidentity-renewal.service" do
  user  "root"
  group "root"
  mode  "0644"
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

need_bootstrap = !run_command("test -e /var/lib/machineidentity/identity.crt -a ! -e /var/lib/machineidentity/force-bootstrap", error: false).success?
need_bootstrap ||= run_command(%(ruby -ropenssl -e 'puts OpenSSL::X509::Certificate.new(ARGF.read).extensions.select {|_| _.oid == "subjectAltName" }.flat_map {|_| _.value.split(/, */).grep(/^DNS:/).map {|s| s[4..-1] } }.sort.join(?,)' /var/lib/machineidentity/identity.crt), error: false).stdout.chomp != (node[:hocho_jwt][:payload][:sans] || []).sort.join(?,)

if need_bootstrap && !node[:packer] && node[:machineidentity][:token]
  p node.hocho_jwt.payload
  execute "systemctl stop machineidentity-renewal.service || :"

  cmd = "env " \
    "CA_URL=#{node[:machineidentity].fetch(:ca_url).shellescape} " \
    "FINGERPRINT=#{node[:machineidentity].fetch(:fingerprint).shellescape} " \
    "/usr/bin/machineidentity-bootstrap " \
    "--token #{node[:machineidentity].fetch(:token).shellescape} " \
    "#{node[:machineidentity].fetch(:common_name).shellescape}"
  execute "machineidentity step ca certificate"do
    command cmd
    user "machineidentity"
  end

end

service "machineidentity-renewal.service" do
  action [:enable, :start]
end
