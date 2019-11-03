node.reverse_merge!(
  prometheus: {
    blackbox_exporter: {
      config: {
        modules: {
          ping: {
            prober: :icmp,
            timeout: '4s',
          },
          http_2xx: {
            prober: :http,
            timeout: '5s',
            http: {
              valid_http_versions: ["HTTP/1.1", "HTTP/2"],
              valid_status_codes: [],  # Defaults to 2xx
              method: :GET,
              no_follow_redirects: false,
            },
          },
        },
      },
    },
  },
)

include_cookbook 'prometheus-blackbox-exporter'
