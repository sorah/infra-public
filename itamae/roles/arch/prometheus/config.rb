node.reverse_merge!(
  prometheus: {
    config: {
      global: {
        scrape_interval: '20s',
        scrape_timeout: '10s',
        evaluation_interval: '20s',
        external_labels: {
          promhost: node[:hostname],
        },
      },
      rule_files: %w(/etc/prometheus/rules/*.yml),
      scrape_configs: [],
      alerting: {
        alert_relabel_configs: [],
        alertmanagers: [
          static_configs: [
            targets: %w(localhost:9093),
          ],
        ],
      },
    },
  },
)

# ...
