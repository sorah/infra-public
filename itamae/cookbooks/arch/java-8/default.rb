node.reverse_merge!(
  archlinux_java: {
    environment: 'java-8-amazon-corretto',
  },
)

package 'amazon-corretto-8'
include_cookbook 'archlinux-java'
