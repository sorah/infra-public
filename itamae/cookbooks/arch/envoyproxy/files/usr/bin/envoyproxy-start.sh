#!/bin/bash
exec /usr/bin/envoy \
  --restart-epoch ${RESTART_EPOCH} \
  --config-path /etc/envoyproxy/${ENVOY_CONFIG_NAME}.json \
  --drain-time-s ${ENVOY_DRAIN_TIME:-60} \
  --service-cluster '<%= node.dig(:envoy,:service_cluster) || "default" %>' \
  --service-node '<%= node.dig(:envoy,:service_node) || node[:desired_hostname] || node[:hostname] %>' \
  --service-zone '<%= node.dig(:envoy,:service_zone) || "default" %>' \
