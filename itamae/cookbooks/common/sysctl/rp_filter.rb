node.reverse_merge!(
  sysctl: {
    rp_filter: {
      default: 2,
    },
  }
)

file "/etc/sysctl.d/rp_filter.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  content "net.ipv4.conf.default.rp_filter = #{node[:sysctl][:rp_filter][:default]}\n"
end
