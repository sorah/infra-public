class AddressData
  include Model

  def initialize(ip, source)
    @ip = ip
    @source = source
  end

  attr_reader :ip, :source

  attribute def tags
    ip.tags.map { |_| _.fetch("name") }
  end

  attribute def v6?
    ip.family.fetch('value') == 6
  end

  attribute def address
    v6? ? ip.address.compressed : ip.address.address
  end

  attribute def fqdn
    name = ip.dns_name
    name && !name.empty? ? name : nil
  end

  attribute def alternate_fqdns
    []
  end

  attribute def dhcp_mac_address
    addr = ip.custom_fields['mac_address'] || ''
    addr.empty? ? nil : addr
  end
end


