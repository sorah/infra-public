#!/bin/bash
exec /usr/bin/envoy \
  --restart-epoch ${RESTART_EPOCH} \
  --config-path /etc/envoyproxy/${ENVOY_CONFIG_NAME}.json \
  --service-cluster '<%= node.dig(:envoy,:service_cluster) || "default" %>' \
  --service-node '<%= node.dig(:envoy,:service_node) || node[:desired_hostname] || node[:hostname] %>' \
  --service-zone '<%= node.dig(:envoy,:service_zone) || "default" %>' \
