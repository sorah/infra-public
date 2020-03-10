include_role 'base'
include_cookbook 'java-8'
include_cookbook 'mongodb-40'

package 'unifi'
service 'unifi.service' do
  action [:enable, :start]
end
