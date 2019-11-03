node.reverse_merge!(
  prometheus: {
    alertmanager: {
      config: {
        global: {
          resolve_timeout: '5m',
        },
        route: {
          routes: [
            {
              group_by: ['alertname', 'instance'],
              group_wait: '12s',
              group_interval: '12s',
              repeat_interval: '1h',
              receiver: 'slack-alert',
            },
          ],
          receiver: 'slack-alert',
        },
        receivers: [
          {
            name: 'slack-alert',
            slack_configs: [
              {
                send_resolved: true,
                api_url: node[:prometheus][:alertmanager].fetch(:slack_url),
                #channel: '#alert',
                title_link: "https://prometheus",
                title: "{{ .CommonLabels.instance }} ({{ .CommonLabels.job }})",
                text: "{{ range .Alerts }}*{{ .Status }}* {{ .Annotations.summary }}\n{{ end }}",
              },
            ],
          },
        ],
        inhibit_rules: [
          #{
          #  source_match: {
          #    severity: 'critical',
          #  },
          #  target_match: {
          #    severity: 'warning',
          #  },
          #  equal: ['alertname', 'dev', 'instance'],
          #},
        ],
      },
    },
  },
)
