node.reverse_merge!(
  sysctl: {
    bridge_nf_call: {
      default: 0,
    },
  }
)

file "/etc/sysctl.d/bridge_nf_call.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  content <<-EOF
net.bridge.bridge-nf-call-arptables = #{node[:sysctl][:bridge_nf_call][:default]}
net.bridge.bridge-nf-call-ip6tables = #{node[:sysctl][:bridge_nf_call][:default]}
net.bridge.bridge-nf-call-iptables = #{node[:sysctl][:bridge_nf_call][:default]}
  EOF
end
