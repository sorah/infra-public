package 'java-runtime-common'
execute "archlinux-java set #{node[:archlinux_java].fetch(:environment).shellescape}" do
  not_if %|test "_$(archlinux-java get)" = "_#{node[:archlinux_java].fetch(:environment).shellescape}"|
end
