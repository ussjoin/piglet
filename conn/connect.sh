#!/bin/bash

PREFIX=/home/pi/piglet/conn

while [ 1 ]
do
pkill dhclient
pkill wpa_supplicant #So I can run it again

sleep 2 # Without a bit of sleep, this thing freaks out from the pkilling.

ifconfig wlan0 up
#ifconfig wlan1 up
perl $PREFIX/scantosupp.pl wlan0 $PREFIX/out.conf
wpa_supplicant -B -i wlan0 -c $PREFIX/out.conf

# OK, so now it's running.

numnetworks=`wpa_cli list_networks | wc -l` # Gives us the number of networks, +2, that wpa_cli sees
numnetworks=`expr $numnetworks - 2`
echo "$numnetworks networks found that we may (or may not) have the credentials to connect to."

success=0

for ((a=0; a < numnetworks ; a++))
do
	echo "Now connecting to network $a."
	wpa_cli select $a
	sleep 5 #It seems to take a second to do the switch.
	wpa_cli status
	dhclient wlan0 -1 #timeout of 20 seconds in /etc/dhcp/dhclient.conf
	if [ $? -eq 0 ] #Yay, it worked!
		then ping -c 3 -I wlan0 8.8.8.8
		if [ $? -eq 0 ] #Houston, we have liftoff.
			then echo "Success!"
			success=1
			break
		fi
	fi
	echo "No success with network $a."
done

if [ $success ]
	then
	while ping -c 3 -I wlan0 8.8.8.8
	do
		echo "`date` Connection alive. Sleeping for 5 seconds."
		sleep 5
	done
else
	echo "No success. Sleeping for five seconds."
	sleep 5
fi

echo "Connection has failed; restarting connection attempt."

pkill dhclient
pkill wpa_supplicant
rm $PREFIX/out.conf

done



