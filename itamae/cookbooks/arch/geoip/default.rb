node.reverse_merge!(
  geoip: {
    maxmind_account_id: node[:secrets].fetch(:maxmind_account_id),
    maxmind_license_key: node[:secrets].fetch(:maxmind_license_key),
    maxmind_edition_ids: %w(GeoLite2-ASN GeoLite2-City GeoLite2-Country),
  },
)
package 'geoip'
package 'libmaxminddb'
package 'geoipupdate'

template '/etc/GeoIP.conf' do
  owner 'root'
  group 'root'
  mode  '0640'
  notifies :run, 'execute[/usr/bin/geoipupdate --config-file /etc/GeoIP.conf]', :immediately
end

execute '/usr/bin/geoipupdate --config-file /etc/GeoIP.conf' do
  action :nothing
end

service 'geoipupdate.timer' do
  action [:enable, :start]
end
