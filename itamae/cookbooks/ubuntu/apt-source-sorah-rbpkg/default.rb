file '/etc/apt/sources.list.d/sorah-rbpkg.list' do
  content "deb [signed-by=/usr/local/share/keyrings/sorah-rbpkg.gpg] https://cache.ruby-lang.org/lab/sorah/deb/ #{node[:release]} main\n"
  mode  '0644'
  owner 'root'
  group 'root'
  notifies :run, "execute[apt-get update]"
end

remote_file "/usr/local/share/keyrings/sorah-rbpkg.gpg" do
  mode  '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[apt-get update]'
end
