r = run_command("ip r get 8.8.8.8").stdout

node.reverse_merge!(
  default_route: {
    via: r.match(/via ([^ ]+)/)[1],
    dev: r.match(/dev ([^ ]+)/)[1],
    src: r.match(/src ([^ ]+)/)[1],
  },
)
