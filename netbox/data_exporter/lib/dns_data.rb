require 'ipaddr'

class DnsData
  class InvalidData < StandardError; end

  def initialize()
    @records = {}
  end

  def get(fqdn, type)
    @records[fqdn] ||= {}
    @records[fqdn][type] ||= []
  end

  def get_reverse(ip)
    get(IPAddr.new(ip).reverse, :PTR)
  end

  def forward(fqdn, type, *records, overwrite: false)
    fqdn = fqdn.gsub(/\.+$/,'')
    get(fqdn, type)
    if overwrite
      @records[fqdn][type] = records.sort.uniq
    else
      @records[fqdn][type].push(*records).sort.uniq
    end
  end

  def cname(fqdn, target)
    forward(fqdn, :CNAME, "#{target}.")
  end

  def reverse(ip, fqdn)
    forward(IPAddr.new(ip).reverse, :PTR, "#{fqdn}.", overwrite: true)
  end

  def check!
    @records.each do |fqdn, types|
      %i(CNAME PTR).each do |cnameptr|
        next unless types.key?(cnameptr)
        if types.size > 1
          raise InvalidData, "#{fqdn.inspect} has #{cnameptr} and other RR: #{types.inspect}"
        end
        if types[cnameptr].size > 1
          raise InvalidData, "#{fqdn.inspect} has #{cnameptr} with many resources: #{types[cnameptr].inspect}"
        end
      end
    end

    @records.each do |fqdn, types|
      next unless types.key?(:CNAME)
      target = types[:CNAME][0]
      traverse_cname(target,[fqdn])
    end
  end

  def dump(zones)
    zones = zones.sort_by(&:size).reverse

    @records.group_by { |(fqdn,_rrset)| zones.find{ |zone| fqdn.end_with?(".#{zone}") } || '.' }.map do |zone, records|
      data = records.flat_map do |fqdn, rrset|
        rrset.map { |type, rr| {'fqdn' => fqdn, 'type' => type.to_s, 'rr' => rr.sort} }
      end.sort_by { |r| [r['fqdn'].split(?.).reverse,r['type']] }
      [ zone, data ]
    end.sort_by(&:first).to_h
  end

  private

  def traverse_cname(target,past)
    target = target[0...-1] if target[-1] == '.'
    if past.include?(target)
      raise InvalidData, "CNAME couldn't traverse (LOOP): #{target.inspect} <= #{past.inspect}"
    end

    rr = @records[target]
    unless rr
      raise InvalidData, "CNAME couldn't traverse: #{target.inspect} <= #{past.inspect}"
    end
    unless rr.key?(:CNAME)
      # puts "CNAME OK: #{[target, *past].reverse.inspect} #{rr.inspect}"
      return
    end
    traverse_cname(rr[:CNAME][0], [target, *past])
  end
end


