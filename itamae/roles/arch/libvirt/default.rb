include_role 'base'

include_cookbook 'qemu'
include_cookbook 'libvirt'

service 'libvirtd.service' do
  action :enable
end
