require 'aws-sdk-ec2'

def render_tags(tags)
  <<-EOF.chomp
  tags = {
#{tags.sort_by(&:key).map{ |_| next if _.key.start_with?("aws:"); "    #{_.key} = \"#{_.value}\"" }.compact.join("\n")}
  }
  EOF
end


Import = Struct.new(:address, :id)
imports = []

provider, region, name = ARGV[0,3]
ec2 = Aws::EC2::Client.new(region: region)

vpc_id_to_name = {}
ec2.describe_vpcs().flat_map(&:vpcs).each.with_object(IO.popen(['terraform', 'state', 'list'], 'r', &:read).scan(/^aws_vpc\.([^.]+)$/).flatten) do |vpc, known_names|
  name = vpc.tags.find{ |_| _.key == 'Name' }&.value
  next unless known_names.include?(name)
  vpc_id_to_name[vpc.vpc_id] = name
end

vpc = ec2.describe_vpcs(filters: [name: 'tag:Name', values: [name]]).vpcs[0]
sgs = ec2.describe_security_groups(filters: [name: 'vpc-id', values: [vpc.vpc_id]]).flat_map(&:security_groups)

sg_id_to_name = {}
ec2.describe_security_groups().flat_map(&:security_groups).each do |sg|
  next unless sg.vpc_id
  sg_id_to_name[sg.group_id] = "#{vpc_id_to_name.fetch(sg.vpc_id)}_#{sg.group_name}"
end

sgs.each do |sg|
  File.open("#{name}_sg_#{sg.group_name}.tf", 'w') do |io|
    io.puts <<~EOF
    resource "aws_security_group" "#{name}_#{sg.group_name}" {
      provider = "aws.#{provider}"
      vpc_id = aws_vpc.#{vpc_id_to_name[sg.vpc_id]}.id
      name = "#{sg.group_name}"
      description = "#{sg.description}"
    EOF
    imports.push Import.new("aws_security_group.#{name}_#{sg.group_name}", sg.group_id)

    {ingress: sg.ip_permissions, egress: sg.ip_permissions_egress}.each do |kind, rules|
      rules.sort_by { |_| [_.from_port || 0, _.to_port || 0] }.each do |rule|
        io.print "  #{kind} "
        io.puts <<~EOF
        {
            protocol = "#{rule.ip_protocol}"
            from_port = #{rule.from_port || 0}
            to_port = #{rule.to_port || 0}
        EOF

        {
          cidr_blocks: (rule.ip_ranges || []).map(&:cidr_ip),
          ipv6_cidr_blocks: (rule.ipv_6_ranges || []).map(&:cidr_ipv_6),
          prefix_list_ids: (rule.prefix_list_ids || []).map(&:prefix_list_id),
          security_groups: (rule.user_id_group_pairs || []).map(&:group_id).reject { |_| _ == sg.group_id }.map { |_| sg_id_to_name[_] ? "${aws_security_group.#{sg_id_to_name[_]}.id}" : _ },
        }.each do |attr, list|
          next if list.empty?
          io.puts "    #{attr} = ["
          list.each do |elem|
            io.puts %(      "#{elem}",)
          end
          io.puts "    ]"
        end
        io.puts "    self = true" if rule.user_id_group_pairs.any? { |_| _.group_id == sg.group_id }
        io.puts "  }"
      end
    end
    io.puts "}"
  end

end

File.open("#{name}_import-sg.sh", "w") do |io|
  io.puts "set -x\nset -e\n"
  imports.each do |i|
    io.puts "terraform import -provider=aws.#{provider} #{i.address} #{i.id}"
  end
end
