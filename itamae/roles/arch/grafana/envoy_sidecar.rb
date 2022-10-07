node.reverse_merge!(
  grafana: {
    sidecar_envoy_config: {
      admin: {
        access_log_path: '/var/log/envoyproxy/admin.log',
        address: {
          socket_address: {
            address: '127.0.0.1',
            port_value: 9901,
          },
        },
      },
      overload_manager: {
        refresh_interval: '0.25s',
        resource_monitors: [
          {
            name: 'envoy.resource_monitors.fixed_heap',
            typed_config: {
              '@type': 'type.googleapis.com/envoy.extensions.resource_monitors.fixed_heap.v3.FixedHeapConfig',
              max_heap_size_bytes: 104857600,  # 100MiB
            },
          },
        ],
        actions: [

          {
            name: 'envoy.overload_actions.shrink_heap',
            triggers: [
              {
                name: 'envoy.resource_monitors.fixed_heap',
                threshold: { value: 0.95 }
              },

            ],
          },
          {
            name: 'envoy.overload_actions.stop_accepting_requests',
            triggers: [
              {
                name: 'envoy.resource_monitors.fixed_heap',
                threshold: { value: 0.98 },
              },
            ],
          },
        ],
      },
      static_resources: {
        listeners: [
          {
            name: 'loki-read',
            address: {
              socket_address: { address: '127.0.0.1', port_value: 3100 },
            },
            #per_connection_buffer_limit_bytes: 32768,  # 32 KiB
            filter_chains: [
              {
                filter_chain_match: {
                  #server_names: ['loki.r.nkmi.me'],
                },
                filters: [
                  {
                    name: 'envoy.filters.network.http_connection_manager',
                    typed_config: {
                      '@type': 'type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager',
                      stat_prefix: 'ingress_http',
                      use_remote_address: true,
                      common_http_protocol_options: {
                        idle_timeout: '3600s',
                      },
                      http2_protocol_options: {
                      },
                      stream_idle_timeout: '300s',
                      route_config: {
                        virtual_hosts: [
                          {
                            name: 'default',
                            domains: ['*'],
                            routes: [
                              {
                                match: { prefix: '/' },
                                route: { cluster: 'loki-read-tls', idle_timeout: '15s' },
                              },
                            ],
                          },
                        ],
                      },
                      http_filters: [
                        {
                          name: 'envoy.buffer',
                          typed_config: {
                            '@type' => 'type.googleapis.com/envoy.extensions.filters.http.buffer.v3.Buffer',
                            max_request_bytes: 1000000000,
                          },
                        },
                        {
                          name: 'envoy.filters.http.router',
                          typed_config: {
                            '@type': 'type.googleapis.com/envoy.extensions.filters.http.router.v3.Router',
                          },
                        },
                      ],
                      access_log: [
                        name: 'envoy.access_loggers.file',
                        typed_config: {
                          '@type': 'type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog',
                          path: '/var/log/envoyproxy/loki.access.log',
                        },
                      ],
                    },
                  },
                ],
              },
            ],
          },
        ],
        clusters: [
          {
            name: 'loki-read-tls',
            type: 'STRICT_DNS',
            connect_timeout: '3s',
            lb_policy: 'ROUND_ROBIN',
            load_assignment: {
              cluster_name: "loki-read-tls",
              endpoints: [
                {
                  lb_endpoints: [
                    {
                      endpoint: {
                        address: {
                          socket_address: {
                            address: "loki.r.nkmi.me",
                            port_value: 443,
                          },
                        },
                      },
                    },
                  ]
                },
              ],
            },
            max_requests_per_connection: 100,
            http2_protocol_options: {},
            transport_socket: {
              name: 'envoy.transport_sockets.tls',
              typed_config: {
                '@type' => 'type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext',
                common_tls_context: { # extensions.transport_sockets.tls.v3.CommonTlsContext
                  alpn_protocols: %w(h2 http/1.1),
                  tls_certificates: [
                    {
                      certificate_chain: {filename: '/var/lib/machineidentity/identity.crt'},
                      private_key: {filename: '/var/lib/machineidentity/key.pem'},
                    },
                  ],
                  validation_context: {
                    #trusted_ca: {filename: '/etc/ssl/self/fe.nkmi.me/trust.pem'},
                    trusted_ca: {filename: '/var/lib/machineidentity/roots.pem'},
                    match_subject_alt_names: {exact: "loki.r.nkmi.me"},
                  },
                },
              },
            },
          },
        ],
      },
    },
  },
)

include_cookbook 'envoyproxy'
node[:prometheus][:exporter_proxy][:exporters][:envoy] = {path: '/envoy/metrics', url: 'http://localhost:9901/stats/prometheus'}
node.dig(:machineidentity, :units_to_reload)&.push('envoyproxy@sidecar.service')

file "/etc/envoyproxy/sidecar.json" do
  content "#{JSON.pretty_generate(node.dig(:grafana,:sidecar_envoy_config))}\n"
  user  'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[envoy -c /etc/envoyproxy/sidecar.json --mode validate]', :immediately
  notifies :reload, 'service[envoyproxy@sidecar.service]'
end

execute 'usermod -a -G machineidentity http' do
  not_if 'id http|grep -q machineidentity'
end

execute 'envoy -c /etc/envoyproxy/sidecar.json --mode validate' do
  user 'http'
  action [:nothing]
end

service 'envoyproxy@sidecar.service' do
  action [:enable, :start]
end


