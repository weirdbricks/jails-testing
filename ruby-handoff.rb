#!/usr/bin/env ruby
#08/27/2013
#Lampros for WeirdBricks

#----set variables for testing----#
jails_requested=3
jail_family_name="ran-tan-plan"
#
#----set variables for testing----#

puts "--Ruby taking over--"

eth_devices=`dmesg | grep -i eth | awk '{print $1}' | awk 'gsub ( ":","" )'`.split( /\r?\n/ )
puts "Found #{eth_devices.count}:#{eth_devices}"

default_route_device=`netstat -rn | grep default | awk '{print $6}'`.strip
puts "Default Route Device is: #{default_route_device}"

if eth_devices.include? default_route_device
	puts "OK: default route device #{default_route_device} matches found devices"
else
	puts "ERROR: default route device #{default_route_device} not included in the above found devices"
end

ip_address=`ifconfig #{default_route_device} | grep inet | awk '{print $2}'`.strip
puts "ipaddress of default_destination_device is #{ip_address}"

#test ipaddress for space
last_octet=ip_address.split('.')[3].to_i+1
if last_octet+jails_requested > 255
	abort "ERROR: not enough ip address space!"
else
	puts "OK: There is enough IP address space to proceed with testing - assigning IPS"
end

ip_address_without_last_octet=ip_address.split('.')[0]+"."+ip_address.split('.')[1]+"."+ip_address.split('.')[2]+"."
puts "IP Address without the last octet is #{ip_address_without_last_octet}"

ip_address_up_to=last_octet+jails_requested-1
jails_ips=Array.new
puts "Generating IP Addresses for test jails.."
for i in last_octet..ip_address_up_to
	  puts ip_address_without_last_octet+i.to_s
	  jails_ips << ip_address_without_last_octet+i.to_s
end

puts "Checking for Jails dependencies.."
if (`pkg_info | grep ezjail | wc -l | grep -v grep | grep -v ruby`.strip.to_i == 0)
	puts "ERROR: ezjail not installed.. installing"
	`pkg_add -r ezjail`
	puts "OK: ezjail installed"
else
	puts "OK: ezjail already installed"
end

if (`grep ezjail_enable /etc/rc.conf -c`.strip.to_i == 0)
	puts "ERROR: ezjail not set in /etc/rc.conf.. adding"
	`echo "ezjail_enable="YES"" >> /etc/rc.conf`
	puts "OK: ezjail added in /etc/rc.conf"
else
	puts "OK: ezjail already in /etc/rc.conf"
end

#check if jails directory exists
if Dir.exists?('/usr/jails/basejail')
	puts "OK: directory /usr/jails/basejail exists - checking size they take up on disk"
	size_usr_jails_basejail=`du -m -s /usr/jails/basejail/ | awk '{print $1}'`.strip.to_i
	if size_usr_jails_basejail < 200 
		puts "ERROR: directory too small (only #{size_usr_jails_basejail} MB) - redownloading - this will take about 5-15 minutes depending on your connection"
		system("ezjail-admin install -h ftp8.freebsd.org")
		puts "OK: redownload complete"
	else
		puts "OK: directory size looks OK (found: #{size_usr_jails_basejail} MB)"
	end
else
	puts "ERROR: directory /usr/jails/basejail does not exist - setting up - this will take about 5-15 minutes depending on your connection"
	system("ezjail-admin install -h ftp8.freebsd.org")
	puts "OK: directory /usr/jails/basejail is now setup"
end

puts "Jails dependencies complete - creating jails.."

def create_jail name, jail_ip_address
	system("ezjail-admin create #{name} '#{jail_ip_address}'")
end

jails_ips.each do |jail_ip|
	jail_name=jail_family_name+jail_ip.split('.')[3]
	create_jail jail_name, jail_ip
end



