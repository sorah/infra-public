include_role 'base'
include_cookbook 'zfs'
include_cookbook 'targetcli'
include_cookbook 'mdadm'
include_cookbook 'lvm'

service 'target.service' do
  action [:enable, :start]
end
