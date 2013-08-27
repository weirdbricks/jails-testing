#!/usr/bin/env ruby
#08/27/2013
#Lampros for WeirdBricks

#----set variables for testing----#
jails_requested=3
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


