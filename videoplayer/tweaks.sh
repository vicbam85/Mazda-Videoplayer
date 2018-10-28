#!/bin/sh

# Video Player v3.6 installer

VP_VER=3.6

get_cmu_sw_version()
{
	_ver=$(/bin/grep "^JCI_SW_VER=" /jci/version.ini | /bin/sed 's/^.*_\([^_]*\)\"$/\1/')
	_patch=$(/bin/grep "^JCI_SW_VER_PATCH=" /jci/version.ini | /bin/sed 's/^.*\"\([^\"]*\)\"$/\1/')
	_flavor=$(/bin/grep "^JCI_SW_FLAVOR=" /jci/version.ini | /bin/sed 's/^.*_\([^_]*\)\"$/\1/')

	if [[ ! -z "${_flavor}" ]]; then
		echo "${_ver}${_patch}-${_flavor}"
	else
		echo "${_ver}${_patch}"
	fi
}

get_cmu_sw_version_only()
{
	_veronly=$(/bin/grep "^JCI_SW_VER=" /jci/version.ini | /bin/sed 's/^.*_\([^_]*\)\"$/\1/')
	echo "${_veronly}"
}

log_message()
{
	echo "$*" 1>2
	echo -e "\n$*" >> "${MYDIR}/AIO_log.txt"
	/bin/fsync "${MYDIR}/AIO_log.txt"
}


show_message()
{
	sleep 3
	killall jci-dialog
	log_message "= POPUP: $* "
	/jci/tools/jci-dialog --info --title="MESSAGE" --text="$*" --no-cancel &
}


show_message_OK()
{
	sleep 3
	killall jci-dialog
	log_message "= POPUP: $* "
	/jci/tools/jci-dialog --confirm --title="CONTINUE INSTALLATION?" --text="$*" --ok-label="YES - GO ON" --cancel-label="NO - ABORT"
	if [ $? != 1 ]
		then
			killall jci-dialog
			break
		else
			show_message "INSTALLATION ABORTED! PLEASE UNPLUG USB DRIVE"
			sleep 5
			exit
		fi
}


add_app_json()
{
	#log_message "mod to /jci/opera/opera_dir/userjs/additionalApps.json"
	
	count=$(grep -c '{ "name": "'"${1}"'", "label": "'"${2}"'" }' /jci/opera/opera_dir/userjs/additionalApps.json)
	#count=$(grep -c '{ "name": "$1", "label": "$2" }' /jci/opera/opera_dir/userjs/additionalApps.json)
	
	if [ "$count" = "0" ]
	then
		mv /jci/opera/opera_dir/userjs/additionalApps.json /jci/opera/opera_dir/userjs/additionalApps.json.old
		echo "$(cat /jci/opera/opera_dir/userjs/additionalApps.json.old)" | grep -v "]" > /jci/opera/opera_dir/userjs/additionalApps.json
		
		count=$(grep -c '}' /jci/opera/opera_dir/userjs/additionalApps.json)
		if [ "$count" != "0" ]
		then
			echo "$(cat /jci/opera/opera_dir/userjs/additionalApps.json)", > /jci/opera/opera_dir/userjs/additionalApps.json
		fi
		
		echo -e '\t{ "name": "'"${1}"'", "label": "'"${2}"'" }' >> /jci/opera/opera_dir/userjs/additionalApps.json
		echo "]" >> /jci/opera/opera_dir/userjs/additionalApps.json
		chmod 755 /jci/opera/opera_dir/userjs/additionalApps.json
	fi
  if [ -e /jci/opera/opera_dir/userjs/nativeApps.js ]
  then
    echo "additionalApps = $(cat /jci/opera/opera_dir/userjs/additionalApps.json)" > /jci/opera/opera_dir/userjs/nativeApps.js
    log_message "Updated nativeApps.js"
  fi
													 
	  
																															  
																						   
	
}



# disable watchdog and allow write access
echo 1 > /sys/class/gpio/Watchdog\ Disable/value
mount -o rw,remount /


MYDIR=$(dirname $(readlink -f $0))
CMU_SW_VER=$(get_cmu_sw_version)
CMU_VER_ONLY=$(get_cmu_sw_version_only)
rm -f "${MYDIR}/AIO_log.txt"


log_message "=== START LOGGING ... ==="
# log_message "=== CMU_SW_VER = ${CMU_SW_VER} ==="
log_message "=== MYDIR = ${MYDIR} ==="
log_message "=== Watchdog temporary disabeld and write access enabled ==="


# first test, if copy from MZD to sd card is working to test correct mount point
cp /jci/sm/sm.conf ${MYDIR}/config
if [ -e ${MYDIR}/config/sm.conf ]
	then
		log_message "=== Copytest to sd card successful, mount point is OK ==="
		rm -f ${MYDIR}/config/sm.conf
	else
		log_message "=== Copytest to sd card not successful, mount point not found! ==="
		/jci/tools/jci-dialog --title="ERROR!" --text="Mount point not found, have to reboot again" --ok-label='OK' --no-cancel &
		sleep 5
		reboot
		exit
fi


show_message_OK "Video Player App Version = ${VP_VER}\n\nCMU Version = ${CMU_SW_VER} : To continue installation press OK"


# a window will appear for 4 seconds to show the beginning of installation
show_message "START OF TWEAK INSTALLATION ..."


# disable watchdogs in /jci/sm/sm.conf to avoid boot loops if somthing goes wrong
if [ ! -e /jci/sm/sm.conf.org ]
	then
		cp -a /jci/sm/sm.conf /jci/sm/sm.conf.org
		log_message "=== Backup of /jci/sm/sm.conf to sm.conf.org ==="
	else log_message "=== Backup of /jci/sm.conf.org already there! ==="
fi
sed -i 's/watchdog_enable="true"/watchdog_enable="false"/g' /jci/sm/sm.conf
sed -i 's|args="-u /jci/gui/index.html"|args="-u /jci/gui/index.html --noWatchdogs"|g' /jci/sm/sm.conf
log_message "=== WATCHDOG IN SM.CONF PERMANENTLY DISABLED ==="


# -- Enable userjs and allow file XMLHttpRequest in /jci/opera/opera_home/opera.ini - backup first - then edit
if [ ! -e /jci/opera/opera_home/opera.ini.org ]
	then
		cp -a /jci/opera/opera_home/opera.ini /jci/opera/opera_home/opera.ini.org
		log_message "=== Backup of /jci/opera/opera_home/opera.ini to opera.ini.org ==="
	else log_message "=== Backup of /jci/opera/opera_home/opera.ini.org already there! ==="
fi

sed -i 's/User JavaScript=0/User JavaScript=1/g' /jci/opera/opera_home/opera.ini

count=$(grep -c "Allow File XMLHttpRequest=" /jci/opera/opera_home/opera.ini)
if [ "$count" = "0" ]
	then
		sed -i '/User JavaScript=.*/a Allow File XMLHttpRequest=1' /jci/opera/opera_home/opera.ini
	else
		sed -i 's/Allow File XMLHttpRequest=.*/Allow File XMLHttpRequest=1/g' /jci/opera/opera_home/opera.ini
fi
log_message "=== ENABLED USERJS AND ALLOWED FILE XMLHTTPREQUEST IN /JCI/OPERA/OPERA_HOME/OPERA.INI  ==="

# Remove fps.js if still exists
if [ -e /jci/opera/opera_dir/userjs/fps.js ]
	then mv /jci/opera/opera_dir/userjs/fps.js /jci/opera/opera_dir/userjs/fps.js.org
	log_message "=== Moved /jci/opera/opera_dir/userjs/fps.js to fps.js.org  ==="
fi


#######################################################################
# Video_Player by many many people
# V3.5 - Mods by vic_bam85 & Trezdog44
#######################################################################

show_message "Video Player Installation"
log_message "=== START IF INSTALLATION VIDEO_APP ==="


#Remove previous files
rm -fr /jci/gui/apps/_videoplayer/


#Copies the additionalApps.js
if [ ! -e /jci/casdk/casdk.aio ]
then
	cp -a ${MYDIR}/config/videoplayer/jci/opera/opera_dir/userjs/additionalApps.js /jci/opera/opera_dir/userjs/
	chmod 755 /jci/opera/opera_dir/userjs/additionalApps.js
fi
cp -a ${MYDIR}/config/videoplayer/jci/opera/opera_dir/userjs/aio.js /jci/opera/opera_dir/userjs/
chmod 755 /jci/opera/opera_dir/userjs/aio.js

#It creates its own json file from scratch if the file does not exists
if [ ! -e /jci/opera/opera_dir/userjs/additionalApps.json ]
then
	#cp -a ${MYDIR}/config/videoplayer/jci/opera/opera_dir/userjs/additionalApps.json /jci/opera/opera_dir/userjs/
	echo "[" > /jci/opera/opera_dir/userjs/additionalApps.json
	echo "]" >> /jci/opera/opera_dir/userjs/additionalApps.json
	chmod 755 /jci/opera/opera_dir/userjs/additionalApps.json
fi


#copies the content of the addon-common folder
cp -a ${MYDIR}/config/videoplayer/jci/gui/addon-common/ /jci/gui/
chmod 755 -R /jci/gui/addon-common/


#remove old port configuration
count=$(grep -c '/jci/gui/addon-common/websocketd --port=55555 sh' /jci/scripts/stage_wifi.sh)
if [ "$count" != "0" ]
then
	sed -i '/### Video player/d' /jci/scripts/stage_wifi.sh
	sed -i '/55555/d' /jci/scripts/stage_wifi.sh
fi


#changes the stage_wifi.sh
log_message "mod to /jci/scripts/stage_wifi.sh"
count=$(grep -c '/jci/gui/addon-common/websocketd --port=9998 sh' /jci/scripts/stage_wifi.sh)
if [ "$count" = "0" ]
	then
		cp /jci/scripts/stage_wifi.sh /jci/scripts/stage_wifi.sh.old
		echo -e '\n\n\n### Video player' >> /jci/scripts/stage_wifi.sh
		echo -e '\n/jci/gui/addon-common/websocketd --port=9998 sh &' >> /jci/scripts/stage_wifi.sh
		chmod 755 /jci/scripts/stage_wifi.sh
fi

#call to the function to populate the json
log_message "mod to /jci/opera/opera_dir/userjs/additionalApps.json"
add_app_json "_videoplayer" "Video Player"

if [ $(get_cmu_sw_version_only) -lt 60 ]
then
  cp -a ${MYDIR}/config/videoplayer/jci/gui/apps/* /jci/gui/apps/
  chmod 755 -R /jci/gui/apps/_videoplayer/
  log_message "Copy files to /jci/gui/apps"
  sed -r -i "s/var useisink = true/var useisink = false/g" /jci/gui/apps/_videoplayer/js/videoplayer-v3.js
else
  mount -o rw,remount /tmp/mnt/resources 
  mkdir -p /tmp/mnt/resources/aio/apps
  cp -a ${MYDIR}/config/videoplayer/jci/gui/apps/* /tmp/mnt/resources/aio/apps
  log_message "Copy files to /tmp/mnt/resources/aio/apps"
  ln -sf /tmp/mnt/resources/aio/apps/_videoplayer /jci/gui/apps/_videoplayer
  log_message "=== Created Symlink To Resources Partition  ==="
fi


log_message "=== END OF COPY ==="

cp -a ${MYDIR}/config/usr/lib/gstreamer-0.10/* /usr/lib/gstreamer-0.10/
cp -a ${MYDIR}/config/videoplayer/usr/lib/libFLAC.so.8.3.0 /usr/lib/
chmod 755 -R /usr/lib/gstreamer-0.10/libgstautodetect.so
chmod 755 -R /usr/lib/gstreamer-0.10/libgstflac.so
chmod 755 -R /usr/lib/libFLAC.so.8.3.0
ln -s /usr/lib/libFLAC.so.8.3.0 /usr/lib/libFLAC.so.8
log_message "===    Copy libs to usr/lib/gstreamer-0.10     ==="


count=$(grep -c '/imx-mm/video-codec' /etc/profile)
if [ "$count" = "0" ]
	then
		sed -i 's/\/imx-mm\/parser/\/imx-mm\/parser:\/usr\/lib\/imx-mm\/video-codec/g' /etc/profile
    log_message "===  Fix exports / codecs  ==="
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/imx-mm/video-codec

rm -f /tmp/root/.gstreamer-0.10/registry.arm.bin
/usr/bin/gst-inspect
log_message "=== Updated gstreamer registry ==="

# a window will appear for asking to reboot automatically
sleep 3
killall jci-dialog
sleep 1
/jci/tools/jci-dialog --confirm --title="VIDEO PLAYER INSTALLED" --text="Click OK to reboot the system"
		if [ $? != 1 ]
		then
			reboot
			exit
		fi
sleep 10
killall jci-dialog
