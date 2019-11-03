node.reverse_merge!(
  mnt_vol: {
    devices: %w(/dev/sdb /dev/nvme0n1 /dev/nvme1n1 /dev/xvdf),
    fstype: 'btrfs',
  }
)

directory '/mnt/vol' do
  owner 'root'
  group 'root'
  mode  '0755'
end

execute 'mkfs /mnt/vol' do
  command(node[:mnt_vol].fetch(:devices).map { |dev| "mkfs.#{node[:mnt_vol].fetch(:fstype)} -L mnt-vol #{dev}" }.join(' || '))
  not_if "test -e /dev/disk/by-label/mnt-vol"
end

fstab "LABEL=mnt-vol" do
  mountpoint '/mnt/vol'
  fstype node[:mnt_vol].fetch(:fstype)
  options 'rw,defaults'
  dump 1
  fsckorder 1
end

execute 'mount /mnt/vol' do
  not_if "grep -q /mnt/vol /proc/mounts"
end
