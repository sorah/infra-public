node.reverse_merge!(
  mnt_vol: {
    device: node[:hocho_ec2] ? '/dev/nvme0n1' : '/dev/sdb',
    label: 'mnt-vol',
    fstype: 'ext4',
  }
)

directory '/mnt/vol' do
  owner 'root'
  group 'root'
  mode  '0755'
end

if node[:packer]
  include_recipe './packer'
else
  execute 'mkfs /mnt/vol' do
    command "mkfs.#{node[:mnt_vol].fetch(:fstype)} -L #{node[:mnt_vol][:label]} #{node[:mnt_vol].fetch(:device)}"
    not_if "grep -q /mnt/vol /proc/mounts"
  end

  fstab "LABEL=#{node[:mnt_vol].fetch(:label)}" do
    mountpoint '/mnt/vol'
    fstype node[:mnt_vol].fetch(:fstype)
    options 'rw,defaults'
    dump 1
    fsckorder 1
  end

  execute 'mount /mnt/vol' do
    not_if "grep -q /mnt/vol /proc/mounts"
  end
end
