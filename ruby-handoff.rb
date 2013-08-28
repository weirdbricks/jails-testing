#!/usr/bin/env ruby
#08/27/2013
#Lampros for WeirdBricks
system("clear")
#----set variables for testing----#
jails_requested=2
jail_family_name="ran-tan-plan"
#
#----set variables for testing----#

puts "--Ruby taking over-- WE'RE TAKING OVER THIS TOWN...!"

#get ethernet devices from dmesg
eth_devices=`dmesg | grep -i eth | awk '{print $1}' | awk 'gsub ( ":","" )'`.split( /\r?\n/ )
puts "Found #{eth_devices.count}:#{eth_devices}"

#get the default route device 
default_route_device=`netstat -rn | grep default | awk '{print $6}'`.strip
puts "Default Route Device is: #{default_route_device}"

#make sure that the default route device matches the ethernet devices we found - sanity check
if eth_devices.include? default_route_device
	puts "OK: default route device #{default_route_device} matches found devices"
else
	abort "ERROR: default route device #{default_route_device} not included in the above found devices"
end

#cool - now grab the current ip address of that device
ip_address=`ifconfig #{default_route_device} | grep inet | awk '{print $2}'`.strip

puts "ipaddress of default_destination_device is #{ip_address}"

filename = "/etc/ssh/sshd_config"
if File.read(filename).include? "#ListenAddress 0.0.0.0"
	puts "ERROR: #{filename} is set to listen to all interfaces: #ListenAddress 0.0.0.0.. modifying" 
	`cp /etc/ssh/sshd_config /etc/ssh/sshd_config_backup`
	text = File.read(filename) 
	puts = text.gsub(/#ListenAddress 0.0.0.0/, "ListenAddress #{ip_address}")
	File.open(filename, "w") { |file| file << puts }
  	puts "INFO: Attempting to restart sshd..."
	system("service sshd restart")
elsif `sockstat -4 | grep -i ssh | grep -v grep | grep -c #{ip_address}`.strip.to_i == 1
	puts "OK: sshd correctly configured for jails"
end

#test ipaddress for space (in case the number is high!)
last_octet=ip_address.split('.')[3].to_i+1
if last_octet+jails_requested > 255
	abort "ERROR: not enough ip address space!"
else
	puts "OK: There is enough IP address space to proceed with testing - assigning IPs"
end

#put together the xxx.xxx.xxx. part so we can later add the 4th octet
ip_address_without_last_octet=ip_address.split('.')[0]+"."+ip_address.split('.')[1]+"."+ip_address.split('.')[2]+"."
puts "IP Address without the last octet is #{ip_address_without_last_octet}"

#put the ip addresses we're going to use into the array jails_ips
ip_address_up_to=last_octet+jails_requested-1
jails_ips=Array.new
puts "Generating IP Addresses for test jails.."
for i in last_octet..ip_address_up_to
	  puts ip_address_without_last_octet+i.to_s
	  jails_ips << ip_address_without_last_octet+i.to_s
end

#check if we have all the packages/configuratioon we need for ezjail-admin (package: ezjail)
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

#function that creates a jail
def create_jail name, jail_ip_address, default_route_device
	system("ezjail-admin create #{name} '#{jail_ip_address}'")
        system("ifconfig #{default_route_device} alias #{jail_ip_address} netmask 0xffffff00")
	system("cp /etc/resolv.conf /usr/jails/#{name}/etc/resolv.conf")
	system("echo \"sshd_enable=YES\" > /usr/jails/#{name}/etc/rc.conf")
	puts "attempting to start jail: #{name}"
	system("ezjail-admin start #{name}")
end

jails_ips.each do |jail_ip|
	jail_name=jail_family_name+jail_ip.split('.')[3]
	create_jail jail_name, jail_ip, default_route_device
end
