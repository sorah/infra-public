require 'aws-sdk-ec2'

def render_tags(tags)
  <<-EOF.chomp
  tags = {
#{tags.sort_by(&:key).map{ |_| next if _.key.start_with?("aws:"); "    #{_.key} = \"#{_.value}\"" }.compact.join("\n")}
  }
  EOF
end

provider, region, name = ARGV[0,3]
ec2 = Aws::EC2::Client.new(region: region)

vpc = ec2.describe_vpcs(filters: [name: 'tag:Name', values: [name]]).vpcs[0]
dopts = ec2.describe_dhcp_options(dhcp_options_ids: [vpc.dhcp_options_id]).dhcp_options[0]

Import = Struct.new(:address, :id)
imports = []

igws = ec2.describe_internet_gateways(filters: [name: 'attachment.vpc-id', values: [vpc.vpc_id]]).internet_gateways
eigws = ec2.describe_egress_only_internet_gateways()
  .flat_map(&:egress_only_internet_gateways)
  .select { |_| _.attachments.map(&:vpc_id).include?(vpc.vpc_id) }

nats = ec2.describe_nat_gateways(filter: [name: 'vpc-id', values: [vpc.vpc_id]]).nat_gateways
nat_eips = nats.map { |_|
  ec2.describe_addresses(filters: [name: 'allocation-id', values: _.nat_gateway_addresses.map(&:allocation_id)])
    .addresses
    .map{ |_| [_.allocation_id, _] }
    .to_h
}

subnets = ec2.describe_subnets(filters: [name: 'vpc-id', values: [vpc.vpc_id]]).subnets

vgws = ec2.describe_vpn_gateways(filters: [name: 'attachment.vpc-id', values: [vpc.vpc_id]]).vpn_gateways
cgws = ec2.describe_customer_gateways().customer_gateways
cgw_id_to_name = cgws.map{ |_| [_.customer_gateway_id, _.tags.find{ |_| _.key == 'Name' }&.value] }.to_h
vpns = ec2.describe_vpn_connections(filters: [name: 'vpn-gateway-id', values: vgws.map(&:vpn_gateway_id)]).flat_map(&:vpn_connections)

rtbs = ec2.describe_route_tables(filters: [name: 'vpc-id', values: [vpc.vpc_id]]).route_tables

vpces = ec2.describe_vpc_endpoints(filters: [name: 'vpc-id', values: [vpc.vpc_id]]).flat_map(&:vpc_endpoints)

subnet_id_to_resource_name = {}
File.open("#{name}_subnets.tf", 'w') do |io|
  public_subnets = []
  private_subnets = []
  subnets.map do |subnet|
    az = subnet.availability_zone[-1]
    tier = subnet.tags.find{ |_| _.key == 'Tier' }.yield_self { |_| raise "no tier tag in #{subnet.subnet_id}" unless _; _.value }
    [az, tier, subnet]
  end.sort_by do |(az,tier,_subnet)|
    [az, tier]
  end.map do |(az,tier,subnet)|
    io.puts <<~EOF
    resource "aws_subnet" "#{name}_#{az}-#{tier}" {
      provider = "aws.#{provider}"
      availability_zone = "#{subnet.availability_zone}" # #{subnet.availability_zone_id}
      vpc_id = "${aws_vpc.#{name}.id}"
      cidr_block = "#{subnet.cidr_block}"
      #{subnet.ipv_6_cidr_block_association_set[0] ? %(ipv6_cidr_block = "#{subnet.ipv_6_cidr_block_association_set[0].ipv_6_cidr_block}") : nil}
      assign_ipv6_address_on_creation = #{subnet.assign_ipv_6_address_on_creation}
      map_public_ip_on_launch = #{subnet.map_public_ip_on_launch}

    #{render_tags(subnet.tags)}
    }

    EOF
    subnet_id_to_resource_name[subnet.subnet_id] = "#{name}_#{az}-#{tier}"
    case tier
    when 'public'
      public_subnets << "#{name}_#{az}-#{tier}"
    when 'private'
      private_subnets << "#{name}_#{az}-#{tier}"
    end
    imports.push Import.new("aws_subnet.#{name}_#{az}-#{tier}", subnet.subnet_id)
  end

  io.puts <<~EOF
  locals {
    #{name}_public_subnet_ids = #{public_subnets.map{ |_| "${aws_subnet.#{_}.id}" }}
    #{name}_private_subnet_ids = #{private_subnets.map{ |_| "${aws_subnet.#{_}.id}" }}
  }
  EOF
end

File.open("#{name}_vpc.tf", 'w') do |io|
  domain_name = dopts.dhcp_configurations.find { |_| _.key == "domain-name" }&.values&.at(0)&.value
  io.puts <<~EOF
  resource "aws_vpc" "#{name}" {
    provider = "aws.#{provider}"
    cidr_block = "#{vpc.cidr_block}"
    assign_generated_ipv6_cidr_block = true
    enable_dns_support = true
    enable_dns_hostnames = true

  #{render_tags(vpc.tags)}
  }

  resource "aws_vpc_dhcp_options" "#{name}" {
    provider = "aws.#{provider}"
    #{domain_name ? %(domain_name = "#{domain_name}") : nil}
    domain_name_servers = #{dopts.dhcp_configurations.find { |_| _.key == "domain-name-servers" }.values.map(&:value).inspect}

  #{render_tags(dopts.tags)}
  }

  resource "aws_vpc_dhcp_options_association" "#{name}" {
    provider = "aws.#{provider}"
    vpc_id = "${aws_vpc.#{name}.id}"
    dhcp_options_id = "${aws_vpc_dhcp_options.#{name}.id}"
  }
  EOF

  imports.push Import.new("aws_vpc.#{name}", vpc.vpc_id)
  imports.push Import.new("aws_vpc_dhcp_options.#{name}", vpc.dhcp_options_id)

  igws.each_with_index do |igw, i|
    i = nil if igws.size < 2
    io.puts <<~EOF

    resource "aws_internet_gateway" "#{name}#{i}" {
      provider = "aws.#{provider}"
      vpc_id = "${aws_vpc.#{name}.id}"
    #{render_tags(igw.tags)}
    }
    EOF
    imports.push Import.new("aws_internet_gateway.#{name}#{i}", igw.internet_gateway_id)
  end

  eigws.each_with_index do |eigw, i|
    i = nil if eigws.size < 2
    io.puts <<~EOF

    resource "aws_egress_only_internet_gateway" "#{name}#{i}" {
      provider = "aws.#{provider}"
      vpc_id = "${aws_vpc.#{name}.id}"
    }
    EOF
    # imports.push Import.new("aws_egress_only_internet_gateway.#{name}#{i}", eigw.egress_only_internet_gateway_id)
  end

  nats.each_with_index do |nat, i|
    n = nats.size < 2 ? nil : "_#{i}"
    eip = nat_eips[i].values.first
    raise if nat_eips[i].size > 1
    unless eip
      p nat
      p nat_eips[i]
      raise
    end
    io.puts <<~EOF
    resource "aws_nat_gateway" "#{name}#{n}" {
      provider = "aws.#{provider}"
      allocation_id = "${aws_eip.nat_#{name}#{n}.id}"
      subnet_id = "${aws_subnet.#{subnet_id_to_resource_name.fetch(nat.subnet_id)}.id}"
    #{render_tags(nat.tags)}
    }
    resource "aws_eip" "nat_#{name}#{n}" {
      provider = "aws.#{provider}"
      vpc = true
    #{render_tags(eip.tags)}
    }
    EOF
    imports.push Import.new("aws_nat_gateway.#{name}#{n}", nat.nat_gateway_id)
    imports.push Import.new("aws_eip.nat_#{name}#{n}", eip.allocation_id)
  end
end

vgw_id_to_resource_name = {}
File.open("#{name}_vgws.tf", 'w') do |io|
  vgws.each_with_index do |vgw|
    i = nil if vgws.size < 2
    vgw_id_to_resource_name[vgw.vpn_gateway_id] = "#{name}#{i}"
    io.puts <<~EOF
    resource "aws_vpn_gateway" "#{name}#{i}" {
      provider = "aws.#{provider}"
      vpc_id = "${aws_vpc.#{name}.id}"
    #{render_tags(vgw.tags)}
    }

    EOF
    imports.push Import.new("aws_vpn_gateway.#{name}#{i}", vgw.vpn_gateway_id)
  end
end

unless File.exist?("cgws_#{provider}.tf")
  File.open("cgws_#{provider}.tf", 'w') do |io|
    cgws.each do |cgw|
      cgw_name = cgw.tags.find{ |_| _.key == 'Name' }&.value
      io.puts <<~EOF
      # TODO: terraform import aws_customer_gateway.#{provider}_#{cgw_name} #{cgw.customer_gateway_id}
      # resource "aws_customer_gateway" "#{provider}_#{cgw_name}" {
      #   provider = "aws.#{provider}"
      #   bgp_asn = #{cgw.bgp_asn}
      #   ip_address = "#{cgw.ip_address}"
      #   type = "#{cgw.type}"
      # #{render_tags(cgw.tags).each_line.map{ |_| "# #{_}"}.join}
      # }
      EOF
    end
  end
end

File.open("#{name}_vpns.tf", 'w') do |io|
  vpns.each do |vpn|
    vpn_name = vpn.tags.find{ |_| _.key == 'Name' }.value.downcase.gsub(/\//,'_')
    io.puts <<~EOF
    resource "aws_vpn_connection" "#{vpn_name}" {
      provider = "aws.#{provider}"
      vpn_gateway_id = "${aws_vpn_gateway.#{vgw_id_to_resource_name.fetch(vpn.vpn_gateway_id)}.id}"
      customer_gateway_id = "#{vpn.customer_gateway_id}" # "${aws_customer_gateway.#{cgw_id_to_name[vpn.customer_gateway_id]}.id}"
      type = "#{vpn.type}"
      #{vpn.options&.static_routes_only ? "static_routes_only = true" : nil}

    #{render_tags(vpn.tags)}
    }

    EOF
    imports.push Import.new("aws_vpn_connection.#{vpn_name}", vpn.vpn_connection_id)
  end
end

rtb_id_to_resource_name = {}
rtbs.map do |rtb|
  tier_tag = rtb.tags.find{ |_| _.key == 'Tier' }
  tier = tier_tag&.value
  if !tier && rtb.associations.any?{ |_| _.main }
    tier = 'main'
  end
  unless tier
    raise "couldn't determine tier for #{rtb.route_table_id}"
  end
  [tier, rtb]
end.group_by(&:first).each do |tier, tier_rtbs|
  tier_rtbs.each_with_index do |(_tier, rtb), i|
    i = nil if tier_rtbs.size < 2
    rtb_id_to_resource_name[rtb.route_table_id] = "#{name}_#{tier}#{i}"
    File.open("#{name}_rtb_#{tier}#{i}.tf", 'w') do |io|
      io.puts <<~EOF
      resource "aws_route_table" "#{name}_#{tier}#{i}" {
        provider = "aws.#{provider}"
        vpc_id = "${aws_vpc.#{name}.id}"
      #{render_tags(rtb.tags)}
      }

      EOF
      imports.push Import.new("aws_route_table.#{name}_#{tier}#{i}", rtb.route_table_id)

      rtb.associations.each do |rtbassoc|
        if rtbassoc.main
          io.puts <<~EOF
          resource "aws_main_route_table_association" "#{name}" {
            provider = "aws.#{provider}"
            vpc_id = "${aws_vpc.#{name}.id}"
            route_table_id = "${aws_route_table.#{name}_#{tier}#{i}.id}"
          }
          EOF
        else
          subnet_name = subnet_id_to_resource_name.fetch(rtbassoc.subnet_id)
          io.puts <<~EOF
          resource "aws_route_table_association" "#{subnet_name}" {
            provider = "aws.#{provider}"
            route_table_id = "${aws_route_table.#{name}_#{tier}#{i}.id}"
            subnet_id = "${aws_subnet.#{subnet_name}.id}"
          }
          EOF
        end
      end

      rtb.propagating_vgws.each do |pvgw|
        io.puts <<~EOF
          resource "aws_vpn_gateway_route_propagation" "#{vgw_id_to_resource_name.fetch(pvgw.gateway_id)}_#{tier}#{i}" {
            provider = "aws.#{provider}"
            route_table_id = "${aws_route_table.#{name}_#{tier}#{i}.id}"
            vpn_gateway_id = "${aws_vpn_gateway.#{vgw_id_to_resource_name.fetch(pvgw.gateway_id)}.id}"
          }
        EOF
      end

      rtb.routes.sort_by { |_| _.destination_cidr_block || _.destination_ipv_6_cidr_block || "" }.each_with_index do |route, routeidx|
        next unless route.origin == 'CreateRoute'
        ipv6 = !!route.destination_ipv_6_cidr_block

        case
        when route.egress_only_internet_gateway_id
          nexthop_kind = 'egress_only_gateway_id'
          nexthop = eigws[0]&.egress_only_internet_gateway_id  == route.egress_only_internet_gateway_id ? "${aws_egress_only_internet_gateway.#{name}.id}" : route.egress_only_internet_gateway_id
          route_name = "eigw#{routeidx}"
        when route.gateway_id
          nexthop_kind = 'gateway_id'
          case route.gateway_id
          when /^igw-/
            nexthop = igws[0]&.internet_gateway_id == route.gateway_id ? "${aws_internet_gateway.#{name}.id}" : route.gateway_id
            route_name = "igw#{routeidx}"
          when /^vpce-/
            next
          when /^vgw-/
            nexthop = vgw_id_to_resource_name[route.gateway_id] ? "${aws_vpn_gateway.#{vgw_id_to_resource_name[route.gateway_id]}.id}" : route.gateway_id
            route_name = "vgw"
          end
        when route.nat_gateway_id
          nexthop_kind = 'nat_gateway_id'
          nexthop = nats[0]&.nat_gateway_id == route.nat_gateway_id ? "${aws_internet_gateway.#{name}.id}" : route.gateway_id
          route_name = "nat"
        when route.transit_gateway_id
          nexthop_kind = 'transit_gateway_id'
          nexthop = route.transit_gateway_id
          route_name = "#{nexthop}-#{routeidx}"
        when route.vpc_peering_connection_id
          nexthop_kind = 'vpc_peering_connection_id'
          nexthop = route.vpc_peering_connection_id
          route_name = "#{nexthop}-#{routeidx}"
        when route.network_interface_id
          nexthop_kind = 'network_interface_id'
          nexthop = route.network_interface_id
          route_name = "#{nexthop}-#{routeidx}"
        when route.instance_id
          nexthop_kind = 'interface_id'
          nexthop = route.interface_id
          route_name = "#{nexthop}-#{routeidx}"
        end
        io.puts <<~EOF

        resource "aws_route" "#{name}_#{tier}#{i}_#{route_name}" {
          provider = "aws.#{provider}"
          route_table_id = "${aws_route_table.#{name}_#{tier}#{i}.id}"
          #{ipv6 ? "destination_ipv6_cidr_block = \"#{route.destination_ipv_6_cidr_block}\"" :  "destination_cidr_block = \"#{route.destination_cidr_block}\""}
          #{nexthop_kind} = "#{nexthop}"
        }
        EOF

        imports.push Import.new("aws_route.#{name}_#{tier}#{i}_#{route_name}", "#{rtb.route_table_id}_#{route.destination_ipv_6_cidr_block || route.destination_cidr_block}")
      end
    end
  end
end

File.open("#{name}_vpces.tf", 'w') do |io|
  vpces.each do |vpce|
    next if vpce.service_name.include?('.vpce-svc-')
    svc = vpce.service_name.split(?.)[-1]
    imports.push Import.new("aws_vpc_endpoint.#{name}_#{svc}", vpce.vpc_endpoint_id)
    case vpce.vpc_endpoint_type
    when 'Gateway'
      io.puts <<~EOF
      resource "aws_vpc_endpoint" "#{name}_#{svc}" {
        provider = "aws.#{provider}"
        vpc_id = "${aws_vpc.#{name}.id}"
        service_name = "#{vpce.service_name}"
      #{render_tags(vpce.tags)}
      }
      EOF

      vpce.route_table_ids.each do |rtb_id|
        rtb_name = rtb_id_to_resource_name.fetch(rtb_id)
        io.puts <<~EOF
        resource "aws_vpc_endpoint_route_table_association" "#{rtb_name}_#{svc}" {
          provider = "aws.#{provider}"
          vpc_endpoint_id = "${aws_vpc_endpoint.#{name}_#{svc}.id}"
          route_table_id = "${aws_route_table.#{rtb_name}.id}"
        }
        EOF
      end
    when 'Interface'
      io.puts <<~EOF
      resource "aws_vpc_endpoint" "#{name}_#{svc}" {
        provider = "aws.#{provider}"
        vpc_id = "${aws_vpc.#{name}.id}"
        service_name = "#{vpce.service_name}"
        vpc_endpoint_type = "Interface"
        private_dns_enabled = #{vpce.private_dns_enabled}

        security_group_ids = [
      #{vpce.groups.map{ |_| %(    "#{_.group_id}", # #{_.group_name}) }.join("\n")}
        ]

      #{render_tags(vpce.tags)}
      }
      EOF

      vpce.subnet_ids.each do |subnet_id|
        subnet_name = subnet_id_to_resource_name.fetch(subnet_id)
        io.puts <<~EOF
        resource "aws_vpc_endpoint_subnet_association" "#{subnet_name}_#{svc}" {
          provider = "aws.#{provider}"
          vpc_endpoint_id = "${aws_vpc_endpoint.#{name}_#{svc}.id}"
          subnet_id = "${aws_subnet.#{subnet_name}.id}"
        }
        EOF
      end
    end
  end
end

File.open("#{name}_import.sh", "w") do |io|
  io.puts "set -x\nset -e\n"
  imports.each do |i|
    io.puts "terraform import -provider=aws.#{provider} #{i.address} #{i.id}"
  end
end
