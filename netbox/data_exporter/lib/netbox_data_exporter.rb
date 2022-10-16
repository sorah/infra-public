require 'ipaddr'
require 'json'
require 'yaml'
require 'netbox-client-ruby'

require_relative './source'
require_relative './model'

require_relative './device_data'
require_relative './interface_data'
require_relative './address_data'
require_relative './dns_data'

require_relative './dns_job'
require_relative './prometheus_job'
require_relative './kea_hosts_job.rb'
