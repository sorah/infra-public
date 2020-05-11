node.reverse_merge!(
  nspawn: {
    machines: {
    },
  },
)

file "/etc/nkmi-nspawn-new.txt" do
  action :delete
end

remote_file '/usr/bin/nkmi-nspawn-new' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory '/var/lib/machines' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory "/etc/systemd/nspawn" do
  owner 'root'
  group 'root'
  mode  '0755'
end

(node.dig(:nspawn, :machines) || {}).each do |name, spec|
  spec.reverse_merge!(
    Exec: {
      Boot: true,
      PrivateUsers: false,
      Capability: 'CAP_IPC_LOCK',
    },
    Network: {
      Zone: 'default',
    },
    Files: {
      Bind: %w(),
    },
  )
  spec.dig(:Files, :Bind).tap do |binds|
    case node[:distro].to_s
    when 'arch'
      binds.push(*%w(/var/cache/pacman)).uniq!
    when 'gentoo'
      binds.push(*%w(/usr/portage /opt/sorah-overlay)).uniq!
    end
  end
  template "/etc/systemd/nspawn/#{name}.nspawn" do
    source 'templates/etc/systemd/nspawn/template.nspawn'
    owner 'root'
    group 'root'
    mode  '0644'
    variables machine: spec, name: name
  end

  service "systemd-nspawn@#{name}" do
    action :enable
  end
end

service "machines.target" do
  action :enable
end
