node.reverse_merge!(
  archlinux_java: {
    environment: 'java-11-amazon-corretto',
  },
)

package 'amazon-corretto-11'
include_cookbook 'archlinux-java'
