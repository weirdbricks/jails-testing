#!/usr/bin/env ruby
#08/27/2013
#Lampros for WeirdBricks
system("clear")

all_jail_status=`ezjail-admin list | grep -v Hostname | grep -v "\\---"`.split( /\r?\n/ )
if all_jail_status.count == 0 
	abort "No jails found"
end
all_jail_status.each do |line|
	if line.split(" ")[0].include? "S"
   		puts "Jail IP: #{line.split(" ")[2]}, Hostname: #{line.split(" ")[3]} is stopped..attempting to delete"
		#system("ezjail-admin delete #{line.split(" ")[3]}")
	elsif line.split(" ")[0].include? "R"
		puts "Jail IP: #{line.split(" ")[2]}, Hostname: #{line.split(" ")[3]} is running..attempting to stop and then delete"
		system("ezjail-admin stop #{line.split(" ")[3]}")
		puts "now, attempting to delete"
		#system("ezjail-admin delete #{line.split(" ")[3]}")
	end
	system("ezjail-admin delete #{line.split(" ")[3]}")
	`chflags -R noschg #{line.split(" ")[4]}`
	`rm -r -f #{line.split(" ")[4]}`
end
