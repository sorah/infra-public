require 'json'

class PrometheusJob
  BUNDLES = {
    'prom/juniper-srx' => %w(
      junos
      snmp/if_mib
      snmp/juniper_alarm
      snmp/juniper_bgp
      snmp/juniper_chassis
      snmp/juniper_dom
      snmp/juniper_jdhcp
      snmp/juniper_spu
    ),
    'prom/juniper-ex' => %w(
      junos
      snmp/if_mib
      snmp/juniper_alarm
      snmp/juniper_chassis
      snmp/juniper_dom
      snmp/juniper_jdhcp
      snmp/juniper_virtualchassis
    ),
  }

  def initialize(hosts)
    @hosts = hosts
  end

  def files
    result.map do |k, v|
      ["prom_#{k}.json", "#{v.to_json}\n"]
    end.to_h
  end

  def result
    return @result if defined? @result

    result = {}
    prom_devices.each do |device|
      tag_matches = device.tags
        .flat_map { |tag| BUNDLES[tag]&.map { |b| "prom/#{b}" } || tag }
        .map { |tag| tag.match(%r{^prom/([^_/]+)(_lo)?(?:/([^/]+))?$}) }
        .compact
        .uniq

      jobs = tag_matches.group_by { |m| m[1] }.uniq
      jobs.each do |job, job_matches|
        lo = job_matches.any? { |m| !(m[2] || '').empty? } ? '_lo' : nil

        modules = job_matches.map { |m| m[3] }.compact.reject(&:empty?)
        modules = [nil] if modules.empty?

        target_iface = device.interface_data.each_value.find { |iface| iface.tags.find { |tag| tag == "prom/#{job}" } }
        address = target_iface&.v4_addresses&.first || device.primary_v4
        next unless address

        job_result = (result["#{job}#{lo}"] ||= [])
        modules.each do |mod|
          labels = {
            fqdn: device.fqdn,
          }
          labels[:__param_module] = mod if mod
          job_result.push(
            targets: [address],
            labels: labels,
          )
        end
      end
    end

    @result = result
  end

  def prom_devices
    @prom_devices ||= @hosts.select { |_| _.tags.any? { |tag| tag.match?(%r{^prom/}) } }
  end
end
