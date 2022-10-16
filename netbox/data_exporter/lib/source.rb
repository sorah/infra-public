module Source
  def self.sites
    @sites ||= paginate { NetboxClientRuby.dcim.sites }.map{ |_| [_.id, _] }.to_h
  end

  def self.devices
    @devices ||= paginate { NetboxClientRuby.dcim.devices }.map{ |_| [_.id, _] }.to_h
  end

  def self.virtual_machines
    @virtual_machines ||= paginate { NetboxClientRuby.virtualization.virtual_machines }.map{ |_| [_.id, _] }.to_h
  end

  def self.device_roles
    @device_roles ||= paginate { NetboxClientRuby.dcim.device_roles }.map{ |_| [_.id, _] }.to_h
  end

  def self.ip_addresses
    @ip_addresses ||= paginate { NetboxClientRuby.ipam.ip_addresses }.map{ |_| [_.id, _] }.to_h
  end

  def self.ip_addresses_interface_map
    @ip_addresses_interface_map ||= ip_addresses.each_value.select { |_| _.assigned_object_type == 'dcim.interface' }.group_by(&:assigned_object_id)
  end

  def self.vlans
    @vlans ||= paginate { NetboxClientRuby.ipam.vlans }.to_a.map{ |_| [_.id, _] }.to_h
  end

  def self.interfaces
    @interfaces ||= paginate { NetboxClientRuby.dcim.interfaces }.group_by { |_| _.device.id }.transform_values { |_| _.sort_by(&:name) }
  end

  def self.virtual_machine_interfaces
    @virtual_machine_interfaces ||= paginate { NetboxClientRuby.virtualization.interfaces }.group_by { |_| _.virtual_machine.id }.transform_values { |_| _.sort_by(&:name) }
  end

  def self.site(id)
    sites.fetch(id)
  end

  def self.device(id)
    devices.fetch(id)
  end

  def self.device_role(id)
    device_roles.fetch(id)
  end

  def self.virtual_machine(id)
    virtual_machines.fetch(id)
  end

  def self.ip_address(id)
    ip_addresses.fetch(id)
  end

  def self.vlan(id)
    vlans.fetch(id)
  end

  def self.interface(device_id)
    interfaces.fetch(device_id, [])
  end

  def self.virtual_machine_interface(vm_id)
    virtual_machine_interfaces.fetch(vm_id, [])
  end

  # Paginate NetboxClientRuby::Entities
  def self.paginate
    items = []
    i = 0
    page = yield # NetboxClientRuby::Entities
    begin
      warn "Loading: #{page.class} (page: #{i})"
      items.concat page.to_a
      i += 1
      page.page(i)
    end while page.length > 0
    items
  end
end
