file '/etc/apt/sources.list.d/nekomit.list' do
  content "deb [signed-by=/usr/local/share/keyrings/nekomit.gpg] https://deb.nekom.it/ #{node[:release]} main\n"
  mode  '0644'
  owner 'root'
  group 'root'
  notifies :run, "execute[apt-get update]"
end

remote_file "/usr/local/share/keyrings/nekomit.gpg" do
  mode  '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[apt-get update]'
end
