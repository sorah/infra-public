# https://github.com/sorah/needroleshere
node.reverse_merge!(
  needroleshere: {
    region: 'ap-northeast-1',
    defaults: {
      mode: 'ecs-relative',
      certificate_path: %w(/var/lib/machineidentity/identity.crt),
      private_key_path: '/var/lib/machineidentity/key.pem',
      # trust_anchor_arn:
      # profile_arn:
      # role_arn:
    },
  },
)

package 'needroleshere'

template '/etc/systemd/system/needroleshere.service' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

template '/etc/systemd/system/needroleshere-dir.service' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

template '/etc/systemd/system/needroleshere.socket' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end
template '/etc/systemd/system/needroleshere-ecs-relative.socket' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[systemctl daemon-reload]'
end

service 'needroleshere.socket' do
  action [:enable, :start]
end
service 'needroleshere-ecs-relative.socket' do
  action [:enable, :start]
end


define :needroleshere_binding, mode: nil, certificate_path: nil, private_key_path: nil, trust_anchor_arn: nil, profile_arn: nil, role_arn: nil, inject_environment_file: true do
  name = params[:name]
  mode = params[:mode] || node.dig(:needroleshere, :defaults).fetch(:mode)
  certificate_path = [*(params[:certificate_path] || node.dig(:needroleshere, :defaults).fetch(:certificate_path))]
  private_key_path = params[:private_key_path] || node.dig(:needroleshere, :defaults).fetch(:private_key_path)
  trust_anchor_arn = params[:trust_anchor_arn] || node.dig(:needroleshere, :defaults).fetch(:trust_anchor_arn)
  profile_arn = params[:trust_anchor_arn] || node.dig(:needroleshere, :defaults).fetch(:profile_arn)

  role_arn_cand = params[:role_arn] || node.dig(:needroleshere, :defaults).fetch(:role_arn)
  role_arn = role_arn_cand.include?(':role/') ? role_arn_cand : "#{node.dig(:needroleshere, :defaults).fetch(:role_arn_prefix)}#{role_arn_cand}"

  template "/etc/systemd/system/needroleshere-bind-#{params[:name]}.service" do
    source 'templates/etc/systemd/system/needroleshere-bind-.service'
    variables(name: name, mode: mode, certificate_path: certificate_path, private_key_path: private_key_path, trust_anchor_arn: trust_anchor_arn, profile_arn: profile_arn, role_arn: role_arn)

    owner 'root'
    group 'root'
    mode '0644'
    notifies :run, 'execute[systemctl daemon-reload]'
  end

  directory "/etc/systemd/system/#{params[:name]}.service.d" do
    owner 'root'
    group 'root'
    mode '0755'
  end

  file "/etc/systemd/system/#{params[:name]}.service.d/10-needroleshere-bind.conf" do
    content <<-EOF
[Service]
EnvironmentFile=/run/needroleshere/env/#{params[:name]}
    EOF
    owner 'root'
    group 'root'
    mode '0755'
    notifies :run, 'execute[systemctl daemon-reload]'
  end

  service "needroleshere-bind-#{params[:name]}.service" do
    action [:enable]
  end
end
