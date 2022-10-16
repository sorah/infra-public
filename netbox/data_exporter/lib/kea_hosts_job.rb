require 'json'
require 'ipaddr'

class KeaHostsJob
  TAG = 'dhcp-static'

  def initialize(hosts, addresses)
    @hosts = hosts
    @addresses = addresses
  end

  Record = Struct.new(:address, :mac_address) do
    def host_id
      address.ip.id
    end

    def dhcp_identifier
      mac_address.split(?:).map { |_| _.to_i(16) }.pack('C*')
    end

    def dhcp_identifier_type
      # https://github.com/isc-projects/kea/blob/d2713aabb412739f30bdf8afd4c542dde4647e98/src/share/database/scripts/pgsql/dhcpdb_create.pgsql#L241
      # hw-address=0
      0
    end

    def ipv4_address
      address.ip.address.to_i
    end

    def dhcp4_subnet_id
      # IPAddress#to_string returns "x.x.x.x/nn" notation
      IPAddr.new(address.ip.address.to_string).to_i
    end

    def to_h
      {
        host_id: host_id,
        dhcp_identifier: dhcp_identifier.unpack('C*'),
        dhcp_identifier_type: dhcp_identifier_type,
        ipv4_address: ipv4_address,
        dhcp4_subnet_id: dhcp4_subnet_id,
      }
    end
  end

  def files
    {"kea_hosts.json" => result.map(&:to_h).to_json}
  end

  def result
    return @result if defined? @result
    @result = records
  end

  def records
    (dhcp_addresses + dhcp_interface_addresses + dhcp_tagged_addresses).sort_by(&:host_id).uniq(&:host_id)
  end

  def dhcp_addresses
    @addresses.select(&:dhcp_mac_address).map { |a| Record.new(a, a.dhcp_mac_address) }
  end

  def dhcp_interface_addresses
    @hosts.flat_map do |h|
      h.interface_data.each_value.select do |i|
        i.tags.include?(TAG)
      end.map do |i|
        [i, i.addresses&.first]
      end.select(&:last).map do |(i, a)|
        Record.new(a, i.mac_address)
      end
    end
  end

  def dhcp_tagged_addresses
    @hosts.flat_map do |h|
      h.interface_data.each_value.map do |i|
        [i, i.addresses.select { |a| a.tags.include?(TAG) }]
      end.reject do |(i, as)|
        as.empty?
      end.flat_map do |(i, as)|
        as.map do |a|
          Record.new(a, i.mac_address)
        end
      end
    end
  end
end
