
#begin endless loop
while true;do

	#set screen size variables from arguments
	x=$1
	y=$2
	x2=x/2
	y2=y/2
	goodip=0

	#determine local network number (e.g. 192.168.0.*) to scan for cameras
	while [ "$goodip" -eq "0" ];do
		#wait until non-169* address assigned by DHCP
		printf "\033c" #clear screen
		ip -o addr show | awk '/brd/ {print $6}' | sed 's/255/*/' > /home/pi/nmapin.txt
		echo "Local network:"
		#cat /home/pi/nmapin.txt
		while IFS=, read ipa;do
			echo $ipa
			if [ ${ipa:0:3} != "169" ]
			then
				goodip=1
				break
			else
				echo "Waiting for DHCP server to assign real IP address..."
				sleep 10
			fi
		done < /home/pi/nmapin.txt
	done

	#scan local network for rtsp cameras
	echo "Searching for RTSP cameras:"
	nmap -p554 -iL /home/pi/nmapin.txt -oG - | awk '/open/ {print $2}' | sed -n '1,4p' > /home/pi/camlist.txt
	cat /home/pi/camlist.txt

	#determine number of cameras by reading camlist.txt
	cameras=0
	while IFS=, read cam;do
		((cameras = cameras + 1))
	done < /home/pi/camlist.txt

	#stop all screens
	echo "Restarting camera windows..."
	sudo killall omxplayer.bin

	#parse camlist.txt and display screens
	echo "Loading $cameras camera(s)..."
	rtsp_user="admin"
	rtsp_pass="camerapass"
	rtsp_suffix="/cam/realmonitor?channel=1&subtype=1"

	camera=0
	while IFS=, read ipaddress;do
		((camera = camera + 1))
		a=0
		b=0
		c=0
		d=0
		if  [ "$camera" -eq "1" ]; then
			((c=x2))
			((d=y2))
			if [ "$cameras" -eq "1" ]; then
				((c=x))
				((d=y))
			fi
		fi
		if [ "$camera" -eq "2" ]; then
			((a=x2))
			((c=x))
			((d=y2))
		fi
		if [ "$camera" -eq "3" ]; then
			((b=y2))
			((c=x2))
			((d=y))
		fi
		if [ "$camera" -eq "4" ]; then
			((a=x2))
			((b=y2))
			((c=x))
			((d=y))
		fi
		screen -dmS camera1 sh -c 'omxplayer --win "'$a' '$b' '$c' '$d'" "rtsp://'$rtsp_user':'$rtsp_pass'@'$ipaddress$rtsp_suffix'"'
	done < /home/pi/camlist.txt

	#repeat every 4 hours in case DHCP server gives cameras new IP addresses
	((h = 60 * 60 * 4))
	sleep $h
done
