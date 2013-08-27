#!/bin/csh
 
#08/27/2013
#Lampros for WeirdBricks
 
#check if curl exists
if ( -e `which curl` ) then
  echo "OK: Curl exists"
else
  echo "ERROR:curl doesn't exist, installing.."
  pkg_add -r curl
endif

#check if installed ruby is version 1.8
if ( `pkg_info | grep ruby | grep 1.8 | wc -l` == 1) then 
  echo "ERROR: Installed Ruby is version 1.8.x  - removing"
  pkg_delete ruby-1.8\*  
else
  echo "OK: Ruby 1.8.x not found"
endif

#check if ruby 1.9 is installed
if ( `pkg_info | grep ruby | grep 1.9 | wc -l` == 1) then
  echo "OK: Ruby 1.9.x is already installed"
else
  echo "ERROR:ruby doesn't exist, installing Ruby 1.9"
  set ruby_package=`curl ftp://ftp.freebsd.org/pub/FreeBSD/ports/i386/packages-9.1-release/All/ | grep "ruby-1.9" | awk '{print $9}'`
  echo "Found package $ruby_package - attempting installation"
  pkg_add ftp://ftp.freebsd.org/pub/FreeBSD/ports/i386/packages-9.1-release/All/$ruby_package
endif

#check if symlink for ruby is in place
if ( -l /usr/local/bin/ruby ) then
  echo "OK: Ruby Symlink exists"
else
  echo "ERROR: Ruby Symlink doesn't exist - adding symlink"
  ln -s /usr/local/bin/ruby19 /usr/local/bin/ruby
endif

#check if symlink for irb is in place
if ( -l /usr/local/bin/irb ) then
  echo "OK: irb Symlink exists"
else
  echo "ERROR: irb Symlink doesn't exist - adding symlink"
  ln -s /usr/local/bin/irb19 /usr/local/bin/irb
endif

 
