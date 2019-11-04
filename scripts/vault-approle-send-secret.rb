#!/usr/bin/env ruby
require 'json'
require 'shellwords'

if ARGV.size < 2
  abort "usage: #$0 role fqdn [profile]"
end

role, fqdn, profile = ARGV[0,3]
profile ||= role

VAULT_HOST = 'vault.nkmi.me'

out = IO.popen(['ssh', fqdn, "ip r get $(dig +short #{VAULT_HOST}|tail -n1)"], 'r', &:read)
puts out
ip = out.match(/src ([^ ]+)/)[1]
puts "CIDR: #{ip}/32"

wrap_json = IO.popen(['vault', 'write', '-wrap-ttl=20s', '-format=json', "auth/approle/role/#{role}/secret-id", "metadata=-", "token_bound_cidrs=#{ip}/32"], 'r+') do |io|
  metadata = {fqdn: fqdn}
  io.puts metadata.to_json
  io.close_write
  io.read
end
raise "Failed to get secret-id" unless $?.success?

wrap = JSON.parse(wrap_json)
token = wrap.dig('wrap_info', 'token')

tmpfile = IO.popen(['ssh', fqdn, 'tmp=$(mktemp); chmod 600 ${tmp} && echo ${tmp} && cat > ${tmp}'], 'r+') do |io|
  io.puts token
  io.close_write
  io.read
end.chomp
raise "Failed to send secret-id" unless $?.success?
puts "tmpfile: #{tmpfile}"
exec "ssh", "-t", fqdn, "sudo vault-approle-keep-feed #{profile} < #{tmpfile.shellescape}; shred --remove #{tmpfile.shellescape}"
