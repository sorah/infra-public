node.reverse_merge!(
  loki: {
    config: {
      target: 'all',
      auth_enabled: true,
      common: {
        ring: { kvstore: { store: 'inmemory' } },
        instance_addr: '127.0.0.1',
        compactor_address: '127.0.0.1',
      },
      server: {
        http_listen_address: "127.0.0.1",
        http_listen_port: 3100,
        grpc_listen_address: "127.0.0.1",
      },
      ingester: {
        lifecycler: {
          address: '127.0.0.1',
          ring: { kvstore: { store: 'inmemory' }, replication_factor: 1 },
          final_sleep: '0s',
        },
        chunk_idle_period: '5m',
        chunk_retain_period: '30s',
        wal: {
          enabled: true,
          dir: '/var/lib/loki/wal',
        },
      },
      distributor: {
        ring: { kvstore: { store: 'inmemory' } },
      },
      compactor: {
        working_directory: '/var/lib/loki/compactor',
        shared_store: 's3',
      },
      schema_config: {
        configs: [
          {
            from: '2022-01-01',
            store: 'boltdb-shipper',
            object_store: 'aws',
            schema: 'v11',
            index: {
              prefix: 'loki_index_',
              period: '24h',
            },
          },
        ],
      },
      storage_config: {
        aws: {
          bucketnames: 'nkmi-loki-apne1',
          endpoint: 's3.dualstack.ap-northeast-1.amazonaws.com',
          region: 'ap-northeast-1',
          sse_encryption: true,
        },
        boltdb_shipper: {
          active_index_directory: '/var/lib/loki/index',
          cache_location: '/var/lib/loki/boltdb-cache',
          shared_store: 's3',
        },
      },
      limits_config: {
        enforce_metric_name: false,
        reject_old_samples: true,
        reject_old_samples_max_age: '168h',
      },
    },
    envoy_config: {
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
            name: 'loki-read-tls',
            address: {
              socket_address: { address: '::', port_value: 443, ipv4_compat: true },
            },
            listener_filters: [
              {
                name: 'envoy.filters.listener.tls_inspector',
                typed_config: {
                  '@type': 'type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector',
                },
              },
            ],
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
                        request_headers_to_add: [
                          { header: { key: 'x-scope-orgid', value: 'nkmi' }, append: true },
                        ],
                        virtual_hosts: [
                          {
                            name: 'default',
                            domains: ['*'],
                            routes: [
                              {
                                match: { prefix: '/' },
                                route: { cluster: 'loki', idle_timeout: '15s' },
                              },
                            ],
                          },
                        ],
                      },
                      http_filters: [
                        {
                          name: 'envoy.health_check',
                          typed_config: {
                            '@type' => 'type.googleapis.com/envoy.extensions.filters.http.health_check.v3.HealthCheck',
                            pass_through_mode: false,
                            headers: [name: ':path', exact_match: '/site/healthcheck'],
                          },
                        },
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
                transport_socket: {
                  name: 'envoy.transport_sockets.tls',
                  typed_config: {
                    '@type': 'type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext',
                    require_client_certificate: true,
                    common_tls_context: {
                      tls_params: {
                        tls_minimum_protocol_version: 'TLSv1_2',
                      },
                      tls_certificates: [
                        {
                          certificate_chain: {filename: '/var/lib/machineidentity/identity.crt'},
                          private_key: {filename: '/var/lib/machineidentity/key.pem'},
                        },
                      ],
                      validation_context: {
                        trusted_ca: {filename: '/var/lib/machineidentity/roots.pem'},
                        match_typed_subject_alt_names: [
                          { san_type: 'DNS', matcher: { exact: "prometheus.r.nkmi.me" } },
                        ],
                      },
                      alpn_protocols: %w(h2 http/1.1),
                    },
                  },
                },
              },
            ],
          },
          {
            name: 'loki-write-tls',
            address: {
              socket_address: { address: '::', port_value: 8443, ipv4_compat: true },
            },
            listener_filters: [
              {
                name: 'envoy.filters.listener.tls_inspector',
                typed_config: {
                  '@type': 'type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector',
                },
              },
            ],
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
                        request_headers_to_add: [
                          { header: { key: 'x-scope-orgid', value: 'nkmi' }, append: true },
                        ],
                        virtual_hosts: [
                          {
                            name: 'default',
                            domains: ['*'],
                            routes: [
                              {
                                match: { path: '/loki/api/v1/push' },
                                route: { cluster: 'loki', idle_timeout: '15s' },
                              },
                            ],
                          },
                        ],
                      },
                      http_filters: [
                        {
                          name: 'envoy.health_check',
                          typed_config: {
                            '@type' => 'type.googleapis.com/envoy.extensions.filters.http.health_check.v3.HealthCheck',
                            pass_through_mode: false,
                            headers: [name: ':path', exact_match: '/site/healthcheck'],
                          },
                        },
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
                transport_socket: {
                  name: 'envoy.transport_sockets.tls',
                  typed_config: {
                    '@type': 'type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext',
                    common_tls_context: {
                      tls_params: {
                        tls_minimum_protocol_version: 'TLSv1_2',
                      },
                      tls_certificates: [
                        {
                          certificate_chain: {filename: '/var/lib/machineidentity/identity.crt'},
                          private_key: {filename: '/var/lib/machineidentity/key.pem'},
                        },
                      ],
                      alpn_protocols: %w(h2 http/1.1),
                    },
                  },
                },
              },
            ],
          }
        ],
        clusters: [
          {
            name: 'loki',
            load_assignment: {
              cluster_name: 'loki',
              endpoints: [
                {
                  lb_endpoints: [
                    {
                      endpoint: {
                        address: {
                          socket_address: { address: '127.0.0.1', port_value: 3100 },
                        },
                      },
                    },
                  ],
                },
              ],
            },
          },
        ],
      },
    },
  },
)

include_role 'loki::config'
include_role 'base'

unless node[:hocho_ec2]
  include_cookbook 'needroleshere'
  needroleshere_binding 'loki' do
    mode 'ecs-relative'
    role_arn 'ec2-loki'
  end
end

include_cookbook 'loki'

template '/etc/systemd/system/loki.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :execute, 'execute[systemctl daemon-reload]'
end

directory '/etc/loki' do
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/etc/loki/loki.yaml' do
  action :delete
end

file '/etc/loki/loki.yml' do
  content "#{JSON.pretty_generate(node[:loki][:config])}\n"
  owner 'root'
  group 'root'
  mode  '0644'
  #notifies :reload, 'service[loki.service]'
end

include_cookbook 'envoyproxy'
node[:prometheus][:exporter_proxy][:exporters][:envoy] = {path: '/envoy/metrics', url: 'http://localhost:9901/stats/prometheus'}
node.dig(:machineidentity, :units_to_reload)&.push('envoyproxy@loki.service')

file "/etc/envoyproxy/loki.json" do
  content "#{JSON.pretty_generate(node.dig(:loki,:envoy_config))}\n"
  user  'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[envoy -c /etc/envoyproxy/loki.json --mode validate]', :immediately
  notifies :reload, 'service[envoyproxy@loki.service]'
end

execute 'usermod -a -G machineidentity http' do
  not_if 'id http|grep -q machineidentity'
end

execute 'envoy -c /etc/envoyproxy/loki.json --mode validate' do
  user 'http'
  action [:nothing]
end

service 'envoyproxy@loki.service' do
  action [:enable, :start]
end


