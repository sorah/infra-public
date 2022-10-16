require_relative './dns_data'

class DnsJob
  ZONES = %w(
    10.in-addr.arpa
    168.192.in-addr.arpa
    254.169.in-addr.arpa

    nkmi.me
    nkmi.net
  )

  def initialize(hosts, addresses)
    @hosts = hosts
    @addresses = addresses
  end

  def files
    {'dns.json' => "#{result.dump(ZONES).to_json}\n"}
  end

  def result
    return @result if defined? @result
    dns = DnsData.new

    @hosts.each do |host|
      dns.forward(host.fqdn4, :A, host.primary_v4) if host.primary_v4
      dns.forward(host.fqdn, :A, host.primary_v4) if host.primary_v4
      dns.forward(host.fqdn, :AAAA, host.primary_v6) if host.primary_v6
      dns.forward(host.public_fqdn4, :A, host.public_v4) if host.public_v4
      dns.forward(host.public_fqdn, :A, host.public_v4) if host.public_v4
      dns.forward(host.public_fqdn, :AAAA, host.public_v6) if host.public_v6

      host.interface_data.each_value do |iface|
        if !host.unmatched_primary_interface? && iface.v4_addresses == [host.primary_v4].compact && iface.v6_addresses == [host.primary_v6].compact && (!iface.v4_addresses.empty? || !iface.v6_addresses.empty?)
          dns.cname(iface.fqdn4, host.fqdn4) if host.primary_v4
          dns.cname(iface.fqdn, host.fqdn)
        else
          iface.v4_addresses.each do |address|
            dns.forward(iface.fqdn4, :A, address)
            dns.forward(iface.fqdn, :A, address)
            dns.reverse(address, iface.fqdn)
          end
          iface.v6_addresses.each do |address|
            dns.forward(iface.fqdn, :AAAA, address)
            dns.reverse(address, iface.fqdn)
          end
        end

        if !host.unmatched_primary_public_interface? && iface.public_v4_addresses == [host.public_v4].compact && iface.public_v6_addresses == [host.public_v6].compact && (!iface.public_v4_addresses.empty? || !iface.public_v6_addresses.empty?)
          dns.cname(iface.public_fqdn4, host.public_fqdn4) if host.public_v4
          dns.cname(iface.public_fqdn, host.public_fqdn)
        else
          iface.public_v4_addresses.each do |address|
            dns.forward(iface.public_fqdn4, :A, address)
            dns.forward(iface.public_fqdn, :A, address)
            dns.reverse(address, iface.public_fqdn)
          end
          iface.public_v6_addresses.each do |address|
            dns.forward(iface.public_fqdn, :AAAA, address)
            dns.reverse(address, iface.public_fqdn)
          end
        end

        dns.cname(iface.fqdn4, iface.public_fqdn4) if iface.v4_addresses.empty? && !iface.public_v4_addresses.empty?
        dns.cname(iface.fqdn, iface.public_fqdn) if (iface.v4_addresses.empty? && iface.v6_addresses.empty?) && (!iface.public_v4_addresses.empty? || !iface.public_v6_addresses.empty?)
      end

      dns.reverse(host.primary_v4, host.fqdn) if host.primary_v4
      dns.reverse(host.primary_v6, host.fqdn) if host.primary_v6
      dns.reverse(host.public_v4, host.public_fqdn) if host.public_v4
      dns.reverse(host.public_v6, host.public_fqdn) if host.public_v6
    end

    @addresses.each do |ip|
      if ip.fqdn
        dns.forward(ip.fqdn, ip.v6? ? :AAAA : :A, ip.address)
        dns.reverse(ip.address, ip.fqdn)
        ip.alternate_fqdns.each do |alt|
          dns.cname(alt, ip.fqdn)
        end
      else
        ip.alternate_fqdns.each do |alt|
          dns.forward(alt, ip.v6? ? :AAAA : :A, ip.address)
        end
      end
    end

    dns.check!
    @result = dns
  end
end
