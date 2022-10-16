class DeviceData
  include Model

  def initialize(dev, source, vm: false)
    @dev = dev
    @source = source
    @vm = vm
  end

  attr_reader :dev, :source

  attribute def vm?
    @vm
  end

  attribute def name
    dev.name
  end

  attribute def name_dns
    @name_dns ||= name
      .downcase
      .gsub(/\.[a-z0-9]+(?:#\d+)?$/, '') # something01.site#2 => something01
      .gsub(/[^a-z0-9\-]/, '-')
      .gsub(/-+/, '-')
      .gsub(/^-+|-+$/, '')
  end

  def site
    source.site(vm? ? dev.site.fetch('id') : dev.site.id)
  end

  attribute def site_name
    site.slug
  end

  def role
    source.device_role(vm? ? dev.role.id : dev.device_role.id)
  end

  attribute def role_name
    role.name
  end

  attribute def tags
    dev.tags.map(&:name)
  end

  def domain
    @domain ||= "#{site_name}.nkmi.me"
  end

  def domain4
    @domain4 ||= "#{site_name}.4.nkmi.me"
  end

  def public_domain
    @public_domain ||= "#{site_name}.nkmi.net"
  end

  def public_domain4
    @public_domain4 ||= "#{site_name}.4.nkmi.net"
  end

  attribute def fqdn
    "#{name_dns}.#{domain}"
  end

  attribute def fqdn4
    "#{name_dns}.#{domain4}"
  end

  attribute def public_fqdn
    "#{name_dns}.#{public_domain}"
  end

  attribute def public_fqdn4
    "#{name_dns}.#{public_domain4}"
  end

  attribute def primary_v4
    return nil unless dev.primary_ip4
    ip = source.ip_address(dev.primary_ip4.id)
    ip.address.address
  end

  attribute def primary_v6
    return nil unless dev.primary_ip6
    ip = source.ip_address(dev.primary_ip6.id)
    ip.address.compressed
  end

  def public_v4_source
    interface_data.each_value.find(&:primary_public_v4_source)&.primary_public_v4_source
  end

  def public_v6_source
    interface_data.each_value.find(&:primary_public_v4_source)&.primary_public_v6_source
  end

  attribute def public_v4
    public_v4_source&.address&.address
  end

  attribute def public_v6
    public_v6_source&.address&.compressed
  end

  attribute def unmatched_primary_interface?
    if dev.primary_ip4 && dev.primary_ip6
      ip4 = source.ip_address(dev.primary_ip4.id)
      ip6 = source.ip_address(dev.primary_ip6.id)
      ip4.interface.id != ip6.interface.id
    else
      false
    end
  end

  attribute def unmatched_primary_public_interface?
    if public_v4_source && public_v6_source
      public_v4_source.interface.id != public_v6_source.interface.id
    else
      false
    end
  end


  def interface_data
    @interfaces ||= (vm? ? source.virtual_machine_interface(dev.id) : source.interface(dev.id)).map do |_|
      i = InterfaceData.new(_, source, self)
      [i.name, i]
    end.to_h
  end

  attribute def interfaces
    interface_data.transform_values(&:to_h)
  end
end
