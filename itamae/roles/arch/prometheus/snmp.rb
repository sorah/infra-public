node.reverse_merge!(
  prometheus: {
    snmp_exporter: {
    },
  },
)

include_cookbook 'prometheus-snmp-exporter'
