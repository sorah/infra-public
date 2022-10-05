#package 'base-devel'

%w(
  autoconf
  automake
  binutils
  bison
  fakeroot
  file
  findutils
  flex
  gawk
  gcc
  gettext
  grep
  groff
  gzip
  libtool
  m4
  make
  pacman
  patch
  pkgconf
  sed
  texinfo
  which
).each do |pkg|
  package pkg
end
