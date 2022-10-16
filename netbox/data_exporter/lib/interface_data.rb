PRIMARY_PUBLIC = "primary-public"

class InterfaceData
  include Model

  def initialize(iface, source, device)
    @iface = iface
    @source = source
    @device = device
  end

  attr_reader :iface, :source, :device

  attribute def name
    iface.name
  end

  attribute def name_dns
    @name_dns ||= case
    when true
      name
        .sub(/TenGiga(?:bit)?Ethernet/i, 'te')
        .sub(/Giga(?:bit)?Ethernet/i, 'gi')
        .sub(/FastEthernet/i, 'fa')
        .sub(/Tunnel/i, 'tun')
        .sub(/Loopback/i, 'lo')
        .sub(/Port-?Channel/i, 'po')
        .sub(/:/, '-p')
        .downcase
        .gsub(/[^a-z0-9\-]/, '-')
        .gsub(/-+/, '-')
        .gsub(/^-+|-+$/, '')
    end
  end

  attribute def tags
    iface.tags.map { |_| _.fetch("name") }
  end

  attribute def mac_address
    iface.mac_address
  end

  PRIVATE_IPV4_NET = %w(
    0.0.0.0/8
    10.0.0.0/8
    172.16.0.0/12
    192.168.0.0/16
    100.64.0.0/10
    127.0.0.0/8
    169.254.0.0/16
    192.0.2.0/24
    198.18.0.0/15
    198.51.100.0/24
    203.0.113.0/24
    224.0.0.0/3
  ).map{ |_| IPAddr.new(_) }

  def addresses_source
    @addresses_source ||= source.ip_addresses_interface_map[iface.id] || []
  end

  def addresses
    @addresses ||= addresses_source.map { |a| AddressData.new(a, source) }
  end

  def categorized_v4_addresses_source
    @categorized_v4_addresses_source ||= addresses_source.select{ |_| _.family.fetch('value') == 4 } # FIXME: fetch('value')
      .partition { |_| IPAddr.new(_.address.address).yield_self { |ip| PRIVATE_IPV4_NET.any? { |net| net.include?(ip) } } }
  end

  def public_v4_addresses_source; categorized_v4_addresses_source[1]; end
  def private_v4_addresses_source; categorized_v4_addresses_source[0]; end

  def categorized_v6_addresses_source
    @categorized_v6_addresses_source ||= [[], addresses_source.select{ |_| _.family.fetch('value') == 6 }]
  end

  def public_v6_addresses_source; categorized_v6_addresses_source[1]; end
  def private_v6_addresses_source; categorized_v6_addresses_source[0]; end

  def primary_public_v4_source
    public_v4_addresses_source.find { |_| _.tags.include?(PRIMARY_PUBLIC) }
  end

  def primary_public_v6_source
    public_v6_addresses_source.find { |_| _.tags.include?(PRIMARY_PUBLIC) }
  end

  attribute def v4_address_cidrs
    private_v4_addresses_source.map { |_| "#{_.address.address}/#{_.address.prefix}" }
  end

  attribute def v4_addresses
    private_v4_addresses_source.map { |_| _.address.address }
  end

  attribute def v6_addresses
    private_v6_addresses_source.map { |_| _.address.compressed }
  end

  attribute def public_v4_addresses
    public_v4_addresses_source.map{ |_| _.address.address }
  end

  attribute def public_v6_addresses
    public_v6_addresses_source.map{ |_| _.address.compressed }
  end

  #FqdnSpecification = Struct.new(
  #  :name,
  #  :public,
  #  :canonical,
  #  keyword_init: true,
  #)

  #def fqdn_specficiations
  #  # [+|~](!)name
  #  @fqdn_specifications ||= (iface.description || '')
  #    .scan(/(\+|~)(!?)([0-9a-z\-\.]+)(\.N)?(?:$| )/)
  #    .map do |(public_sign,canonical_sign,name,nkmime)|
  #    FqdnSpecification.new(
  #      name: [name.include?('.') ? name : "#{name}.#{device.fqdn}", nkmime ? '.nkmi.me' : nil].join,
  #      public: public_sign == '~',
  #      canonical: canonical_sign == '!',
  #    )
  #  end
  #end

  #attribute def alternate_canonical_fqdn
  #  fqdn_specficiations.reject(&:public).find(&:canonical)&.name
  #end

  #attribute def alternate_canonical_public_fqdn
  #  fqdn_specficiations.select(&:public).find(&:canonical)&.name
  #end

  attribute def auto_fqdn
    "#{name_dns}.#{device.fqdn}"
  end

  attribute def auto_public_fqdn
    "#{name_dns}.#{device.public_fqdn}"
  end

  attribute def fqdn
    auto_fqdn
  end

  attribute def public_fqdn
    auto_public_fqdn
  end

  attribute def fqdn4
    "#{name_dns}.#{device.fqdn4}"
  end

  attribute def public_fqdn4
    "#{name_dns}.#{device.public_fqdn4}"
  end

  #attribute def alternate_fqdns
  #  fqdn_specficiations.reject(&:public).reject(&:canonical).map(&:name) + (alternate_canonical_fqdn ? [auto_fqdn] : [])
  #end

  #attribute def alternate_public_fqdns
  #  fqdn_specficiations.select(&:public).reject(&:canonical).map(&:name) + (alternate_canonical_public_fqdn ? [auto_public_fqdn] : [])
  #end
end


