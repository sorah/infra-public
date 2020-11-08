node.reverse_merge!(
  fuse: {
    mount_max: 1000,
    user_allow_other: false,
  },
)
package 'fuse2'

template '/etc/fuse.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
end
