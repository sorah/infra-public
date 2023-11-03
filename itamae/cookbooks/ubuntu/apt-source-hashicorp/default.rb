# https://www.hashicorp.com/official-packaging-guide
file '/etc/apt/sources.list.d/hashicorp.list' do
  content "deb [signed-by=/usr/local/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com #{node[:release]} main\n"
  mode  '0644'
  owner 'root'
  group 'root'
  notifies :run, "execute[apt-get update]"
end

remote_file "/usr/local/share/keyrings/hashicorp.gpg" do
  mode  '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[apt-get update]'
end
