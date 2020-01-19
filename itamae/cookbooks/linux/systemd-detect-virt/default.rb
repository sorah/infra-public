virt = run_command("systemd-detect-virt --container", error: false).stdout.chomp
node.reverse_merge!(
  systemd_detect_virt: virt,
  in_container: run_command("systemd-detect-virt --container", error: false).exit_status == 0,
  in_chroot: run_command("systemd-detect-virt --chroot", error: false).exit_status == 0,
)
