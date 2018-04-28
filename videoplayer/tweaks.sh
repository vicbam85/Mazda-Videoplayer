#!/bin/sh
# tweaks.sh - MZD-AIO-TI Version 2.7.4
# Special thanks to Siutsch for collecting all the tweaks and for the original AIO
# Big Thanks to Modfreakz, khantaena, Xep, ID7, Doog, Diginix, oz_paulb & lmagder
# For more information visit https://mazdatweaks.com
# Enjoy, Trezdog44 - Trevelopment.com

# Time
hwclock --hctosys

# AIO Variables
AIO_VER=2.7.4
AIO_DATE=2017.12.24

KEEPBKUPS=0
TESTBKUPS=0
SKIPCONFIRM=0
ZIPBACKUP=0
FORCESSH=0

timestamp()
{
  date +"%D %T"
}
get_cmu_sw_version()
{
  _ver=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')
  _patch=$(grep "^JCI_SW_VER_PATCH=" /jci/version.ini | sed 's/^.*\"\([^\"]*\)\"$/\1/')
  _flavor=$(grep "^JCI_SW_FLAVOR=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')

  if [ ! -z "${_flavor}" ]; then
    echo "${_ver}${_patch}-${_flavor}"
  else
    echo "${_ver}${_patch}"
  fi
}
get_cmu_ver()
{
  _ver=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 1)
  echo ${_ver}
}
			 
 
				
									 
								   
 
		  
 
						   
	  
				  
										 
									   
	
 
				 
						  
												 
				
 
									  
		  
	  
		  
	
 
			   
 
				
																   
	  
													
															 
									 
																								  
	
 
compatibility_check()
{
  # Compatibility check falls into 5 groups:
  # 59.00.5XX ($COMPAT_GROUP=5)
  # 59.00.4XX ($COMPAT_GROUP=4)
  # 59.00.3XX ($COMPAT_GROUP=3)
  # 58.00.XXX ($COMPAT_GROUP=2)
  # 55.00.XXX - 56.00.XXX ($COMPAT_GROUP=1)
  _VER=$(get_cmu_ver)
  _VER_EXT=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 3)
  _VER_MID=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 2)
  if [ $_VER_MID -ne "00" ] # Only development versions have numbers other than '00' in the middle
  then
    echo 0 && return
  fi
  if [ $_VER -eq 55 ] || [ $_VER -eq 56 ]
  then
    echo 1 && return
  elif [ $_VER -eq 58 ]
  then
    echo 2 && return
  elif [ $_VER -eq 59 ]
  then
    if [ $_VER_EXT -lt 400 ] # v59.00.300-400
    then
      echo 3 && return
    elif [ $_VER_EXT -lt 500 ] # v59.00.400-500
    then
      echo 4 && return
    elif [ $_VER_EXT -lt 510 ]
    then
      echo 5 && return # 59.00.502 is another level because it is not compatible with USB Audio Mod
    else
      echo 0 && return
    fi
  else
    echo 0
  fi
}
log_message()
{
  echo "$*" 1>&2
  echo "$*" >> "${MYDIR}/AIO_log.txt"
  /bin/fsync "${MYDIR}/AIO_log.txt"
}
aio_info()
{
  if [ ${KEEPBKUPS} -eq 1 ]
  then
    echo "$*" 1>&2
    echo "$*" >> "${MYDIR}/AIO_info.json"
    /bin/fsync "${MYDIR}/AIO_info.json"
  fi
}
remove_aio_css()
{
  sed -i "/.. MZD-AIO-TI *${2} *CSS ../,/.. END AIO *${2} *CSS ../d" "${1}"
  INPUT=${1##*/}
  log_message "===                Removed ${2} CSS From ${INPUT}                ==="
}
remove_aio_js()
{
  sed -i "/.. MZD-AIO-TI.${2}.JS ../,/.. END AIO.${2}.JS ../d" "${1}"
  INPUT=${1##*/}
  log_message "===              Removed ${2} JavaScript From ${INPUT}             ==="
}
show_message()
{
  sleep 5
  killall jci-dialog
  #	log_message "= POPUP: $* "
  /jci/tools/jci-dialog --info --title="MZD-AIO-TI  v.${AIO_VER}" --text="$*" --no-cancel &
}
show_message_OK()
{
  sleep 4
  killall jci-dialog
  #	log_message "= POPUP: $* "
  /jci/tools/jci-dialog --confirm --title="MZD-AIO-TI | CONTINUE INSTALLATION?" --text="$*" --ok-label="YES - GO ON" --cancel-label="NO - ABORT"
  if [ $? != 1 ]
  then
    killall jci-dialog
    return
  else
    log_message "********************* INSTALLATION ABORTED *********************"
    show_message "INSTALLATION ABORTED! PLEASE UNPLUG USB DRIVE"
    sleep 10
    killall jci-dialog
    exit 0
  fi
}
add_app_json()
# script by vic_bam85
{
  # check if entry in additionalApps.json still exists, if so nothing is to do
  count=$(grep -c '{ "name": "'"${1}"'"' /jci/opera/opera_dir/userjs/additionalApps.json)
  if [ "$count" = "0" ]
  then
    log_message "=== ${2} not found in additionalApps.json, first installation ==="
    mv /jci/opera/opera_dir/userjs/additionalApps.json /jci/opera/opera_dir/userjs/additionalApps.json.old
    sleep 2
    # delete last line with "]" from additionalApps.json
    grep -v "]" /jci/opera/opera_dir/userjs/additionalApps.json.old > /jci/opera/opera_dir/userjs/additionalApps.json
    sleep 2
    cp /jci/opera/opera_dir/userjs/additionalApps.json "${MYDIR}/bakups/test/additionalApps${1}-2._delete_last_line.json"
    # check, if other entrys exists
    count=$(grep -c '}' /jci/opera/opera_dir/userjs/additionalApps.json)
    if [ "$count" != "0" ]
    then
      # if so, add "," to the end of last line to additionalApps.json
      echo "$(cat /jci/opera/opera_dir/userjs/additionalApps.json)", > /jci/opera/opera_dir/userjs/additionalApps.json
      sleep 2
      cp /jci/opera/opera_dir/userjs/additionalApps.json "${MYDIR}/bakups/test/additionalApps${1}-3._add_comma_to_last_line.json"
      log_message "===           Found existing entrys in additionalApps.json            ==="
    fi
    # add app entry and "]" again to last line of additionalApps.json
    log_message "===        Add ${2} to last line of additionalApps.json         ==="
    echo '  { "name": "'"${1}"'", "label": "'"${2}"'" }' >> /jci/opera/opera_dir/userjs/additionalApps.json
    sleep 2
    if [ ${3} != "" ]
    then
      sed -i 's/"label": "'"${2}"'" \}/"label": "'"${2}"'", "preload": "'"${3}"'" \}/g' /jci/opera/opera_dir/userjs/additionalApps.json
    fi
    cp /jci/opera/opera_dir/userjs/additionalApps.json "${MYDIR}/bakups/test/additionalApps${1}-4._add_entry_to_last_line.json"
    echo "]" >> /jci/opera/opera_dir/userjs/additionalApps.json
    sleep 2
    cp /jci/opera/opera_dir/userjs/additionalApps.json "${MYDIR}/bakups/test/additionalApps${1}-5._after.json"
    rm -f /jci/opera/opera_dir/userjs/additionalApps.json.old
  else
    log_message "===        ${2} already exists in additionalApps.json          ==="
  fi
													 
	  
																															  
																						   
	
}
remove_app_json()
# script by vic_bam85
{
														  
  # check if app entry in additionalApps.json still exists, if so, then it will be deleted
  count=$(grep -c '{ "name": "'"${1}"'"' /jci/opera/opera_dir/userjs/additionalApps.json)
  if [ "$count" -gt "0" ]
  then
    log_message "====  Remove ${count} entry(s) of ${1} found in additionalApps.json   ==="
    mv /jci/opera/opera_dir/userjs/additionalApps.json /jci/opera/opera_dir/userjs/additionalApps.json.old
    # delete last line with "]" from additionalApps.json
    grep -v "]" /jci/opera/opera_dir/userjs/additionalApps.json.old > /jci/opera/opera_dir/userjs/additionalApps.json
    sleep 2
    cp /jci/opera/opera_dir/userjs/additionalApps.json "${MYDIR}/bakups/test/additionalApps${1}-2._delete_last_line.json"
    # delete all app entrys from additionalApps.json
    sed -i "/${1}/d" /jci/opera/opera_dir/userjs/additionalApps.json
    sleep 2
    json="$(cat /jci/opera/opera_dir/userjs/additionalApps.json)"
    # check if last sign is comma
    rownend=$(echo -n $json | tail -c 1)
    if [ "$rownend" = "," ]
    then
      # if so, remove "," from back end
      echo ${json%,*} > /jci/opera/opera_dir/userjs/additionalApps.json
      sleep 2
      log_message "===  Found comma at last line of additionalApps.json and deleted it   ==="
    fi
    cp /jci/opera/opera_dir/userjs/additionalApps.json "${MYDIR}/bakups/test/additionalApps${1}-3._delete_app_entry.json"
    # add "]" again to last line of additionalApps.json
    echo "]" >> /jci/opera/opera_dir/userjs/additionalApps.json
    sleep 2
    first=$(head -c 1 /jci/opera/opera_dir/userjs/additionalApps.json.old)
    if [ $first != "[" ]
    then
      sed -i "1s/^/[\n/" /jci/opera/opera_dir/userjs/additionalApps.json
      log_message "===             Fixed first line of additionalApps.json               ==="
    fi
    rm -f /jci/opera/opera_dir/userjs/additionalApps.json.old
    cp /jci/opera/opera_dir/userjs/additionalApps.json "${MYDIR}/bakups/test/additionalApps${1}-4._after.json"
  else
    log_message "===            ${1} not found in additionalApps.json              ==="
  fi
														  
													 
	  
																															  
																						   
	
}
# disable watchdog and allow write access
echo 1 > /sys/class/gpio/Watchdog\ Disable/value
mount -o rw,remount /

MYDIR=$(dirname "$(readlink -f "$0")")
CMU_VER=$(get_cmu_ver)
CMU_SW_VER=$(get_cmu_sw_version)
COMPAT_GROUP=$(compatibility_check)
rm -f "${MYDIR}/AIO_log.txt"
rm -f "${MYDIR}/AIO_info.json"
		   
mkdir -p "${MYDIR}/bakups/test/"
									  
											   
										
	
										   
																	 
													
  
							  

log_message "========================================================================="
log_message "=======================   START LOGGING TWEAKS...  ======================"
log_message "======================= AIO v.${AIO_VER}  -  ${AIO_DATE} ======================"
log_message "======================= CMU_SW_VER = ${CMU_SW_VER} ======================"
log_message "=======================  COMPATIBILITY_GROUP  = ${COMPAT_GROUP} ======================="
#log_message "======================== CMU_VER = ${CMU_VER} ====================="
							  
																						 
																				  
	
log_message ""
												 
  
log_message "=======================   MYDIR = ${MYDIR}    ======================"
log_message "==================      DATE = $(timestamp)        ================="

show_message "==== MZD-AIO-TI  ${AIO_VER} ====="

aio_info '{"info":{'
aio_info \"CMU_SW_VER\": \"${CMU_SW_VER}\",
aio_info \"AIO_VER\": \"${AIO_VER}\",
aio_info \"USB_PATH\": \"${MYDIR}\",
aio_info \"KEEPBKUPS\": \"${KEEPBKUPS}\"
aio_info '},'
# first test, if copy from MZD to usb drive is working to test correct mount point
cp /jci/sm/sm.conf "${MYDIR}"
if [ -e "${MYDIR}/sm.conf" ]
then
  log_message "===         Copytest to sd card successful, mount point is OK         ==="
  log_message " "
  rm -f "${MYDIR}/sm.conf"
else
  log_message "===     Copytest to sd card not successful, mount point not found!    ==="
  /jci/tools/jci-dialog --title="ERROR!" --text="Mount point not found, have to reboot again" --ok-label='OK' --no-cancel &
  sleep 5
  reboot
fi
if [ $COMPAT_GROUP -eq 0 ] && [ $CMU_VER -lt 55 ]
then
  show_message "PLEASE UPDATE YOUR CMU FW TO VERSION 55 OR HIGHER\nYOUR FIRMWARE VERSION: ${CMU_SW_VER}\n\nUPDATE TO VERSION 55+ TO USE AIO"
  mv ${MYDIR}/tweaks.sh ${MYDIR}/_tweaks.sh
  show_message "INSTALLATION ABORTED REMOVE USB DRIVE NOW" && sleep 5
  log_message "************************* INSTALLATION ABORTED **************************" && reboot
  exit 1
fi
 # Compatibility Check
if [ $COMPAT_GROUP -ne 0 ]
then
  if [ ${SKIPCONFIRM} -eq 1 ]
  then
    show_message "MZD-AIO-TI v.${AIO_VER}\nDetected compatible version ${CMU_SW_VER}\nContinuing Installation..."
    sleep 5
  else
    show_message_OK "MZD-AIO-TI v.${AIO_VER}\nDetected compatible version ${CMU_SW_VER}\n\n To continue installation choose YES\n To abort choose NO"
  fi
  log_message "=======        Detected compatible version ${CMU_SW_VER}          ======="
  if [ ${COMPAT_GROUP} -eq 1 ]
  then
    APP_PATCH_59=1
  else
    APP_PATCH_59=0
  fi
else
  # Removing the comment (#) from the following line will allow MZD-AIO-TI to run with unknown fw versions ** ONLY MODIFY IF YOU KNOW WHAT YOU ARE DOING **
  # show_message_OK "Detected previously unknown version ${CMU_SW_VER}!\n\n To continue anyway choose YES\n To abort choose NO"
  log_message "Detected previously unknown version ${CMU_SW_VER}!"
  show_message "Sorry, your CMU Version is not compatible with MZD-AIO-TI\nE-mail aio@mazdatweaks.com with your\nCMU version: ${CMU_SW_VER} for more information"
  sleep 10
  show_message "UNPLUG USB DRIVE NOW"
  sleep 15
  killall jci-dialog
  # To run unknown FW you need to comment out or remove the following 2 lines
  mount -o ro,remount /
  exit 0
fi
# a window will appear for 4 seconds to show the beginning of installation
show_message "START OF TWEAK INSTALLATION\nMZD-AIO-TI v.${AIO_VER} By: Trezdog44 & Siutsch\n(This and the following message popup windows\n DO NOT have to be confirmed with OK)\nLets Go!"
log_message " "
log_message "======***********    BEGIN PRE-INSTALL OPERATIONS ...    **********======"

# disable watchdogs in /jci/sm/sm.conf to avoid boot loops if something goes wrong
if [ ! -e /jci/sm/sm.conf.org ]
then
  cp -a /jci/sm/sm.conf /jci/sm/sm.conf.org
  log_message "===============  Backup of /jci/sm/sm.conf to sm.conf.org  =============="
else
  log_message "================== Backup of sm.conf.org already there! ================="
fi
sed -i 's/watchdog_enable="true"/watchdog_enable="false"/g' /jci/sm/sm.conf
sed -i 's|args="-u /jci/gui/index.html"|args="-u /jci/gui/index.html --noWatchdogs"|g' /jci/sm/sm.conf
log_message "===============  Watchdog In sm.conf Permanently Disabled! =============="

# -- Enable userjs and allow file XMLHttpRequest in /jci/opera/opera_home/opera.ini - backup first - then edit
if [ ! -e /jci/opera/opera_home/opera.ini.org ]
then
  cp -a /jci/opera/opera_home/opera.ini /jci/opera/opera_home/opera.ini.org
  log_message "======== Backup /jci/opera/opera_home/opera.ini to opera.ini.org ========"
else
  log_message "================== Backup of opera.ini already there! ==================="
fi
sed -i 's/User JavaScript=0/User JavaScript=1/g' /jci/opera/opera_home/opera.ini
count=$(grep -c "Allow File XMLHttpRequest=" /jci/opera/opera_home/opera.ini)
skip_opera=$(grep -c "Allow File XMLHttpRequest=1" /jci/opera/opera_home/opera.ini)
if [ "$skip_opera" -eq "0" ]
then
  if [ "$count" -eq "0" ]
  then
    sed -i '/User JavaScript=.*/a Allow File XMLHttpRequest=1' /jci/opera/opera_home/opera.ini
  else
    sed -i 's/Allow File XMLHttpRequest=.*/Allow File XMLHttpRequest=1/g' /jci/opera/opera_home/opera.ini
  fi
  log_message "============== Enabled Userjs & Allowed File Xmlhttprequest ============="
  log_message "==================  In /jci/opera/opera_home/opera.ini =================="
else
  log_message "============== Userjs & File Xmlhttprequest Already Enabled ============="
fi

# Remove fps.js if still exists
if [ -e /jci/opera/opera_dir/userjs/fps.js ]
then
  mv /jci/opera/opera_dir/userjs/fps.js /jci/opera/opera_dir/userjs/fps.js.org
  log_message "======== Moved /jci/opera/opera_dir/userjs/fps.js to fps.js.org ========="
fi
# Fix missing /tmp/mnt/data_persist/dev/bin/ if needed
if [ ! -e /tmp/mnt/data_persist/dev/bin/ ]
then
  mkdir -p /tmp/mnt/data_persist/dev/bin/
  log_message "======== Restored Missing Folder /tmp/mnt/data_persist/dev/bin/ ========="
fi
log_message "=========************ END PRE-INSTALL OPERATIONS ***************========="
log_message " "
log_message "==========************* BEGIN INSTALLING TWEAKS **************==========="
log_message " "

# start JSON array of backups
if [ "${KEEPBKUPS}" -eq 1 ]
then
  aio_info '"Backups": ['
fi

#######################################################################
# Video_Player by many many people
# V3.4 - Mods by vic_bam85 & Trezdog44
#######################################################################
show_message "VIDEOPLAYER v3.4\nMODS BY VIC_BAM85 & TREZDOG44"
log_message "============***********   INSTALL VIDEOPLAYER   ************============="

log_message "===             Begin Installation of VideoPlayer V3.4                ==="

if [ "${TESTBKUPS}" = "1" ]
then
  cp /jci/scripts/stage_wifi.sh "${MYDIR}/bakups/test/stage_wifi_videoplayer-before.sh"
  cp /jci/opera/opera_dir/userjs/additionalApps.json "${MYDIR}/bakups/test/additionalApps_videoplayer-1._before.json"
fi

### Kills all WebSocket daemons
pkill websocketd

# Remove previous files
rm -fr /jci/gui/apps/_videoplayer/
sed -i '/Video/d' /jci/scripts/stage_wifi.sh
sed -i '/--port=9998/d' /jci/scripts/stage_wifi.sh

# Copies the additionalApps.js
if [ ! -e /jci/opera/opera_dir/userjs/additionalApps.js ]
then
	cp -a ${MYDIR}/config/videoplayer/jci/opera/opera_dir/userjs/additionalApps.js /jci/opera/opera_dir/userjs/
	chmod 755 /jci/opera/opera_dir/userjs/additionalApps.js
  log_message "===                     Copied  additionalApps.js                     ==="
fi

# It creates its own json file from scratch if the file does not exists
if [ ! -e /jci/opera/opera_dir/userjs/additionalApps.json ]
then
	cp -a ${MYDIR}/config/videoplayer/jci/opera/opera_dir/userjs/additionalApps.json /jci/opera/opera_dir/userjs/
	# echo "[" > /jci/opera/opera_dir/userjs/additionalApps.json
	# echo "]" >> /jci/opera/opera_dir/userjs/additionalApps.json
	chmod 755 /jci/opera/opera_dir/userjs/additionalApps.json
  log_message "===                   Created additionalApps.json                     ==="
fi

										   
										  

# Copies the content of the addon-common folder
																								   
cp -a ${MYDIR}/config/videoplayer/jci/gui/addon-common/ /jci/gui/
chmod 755 -R /jci/gui/addon-common/
log_message "===                      Copied addon-common folder                   ==="
  

# Remove old port configuration
count=$(grep -c '/jci/gui/addon-common/websocketd --port=55555 sh' /jci/scripts/stage_wifi.sh)
if [ "$count" != "0" ]
then
	sed -i '/### Video player/d' /jci/scripts/stage_wifi.sh
	sed -i '/55555/d' /jci/scripts/stage_wifi.sh
  log_message "===                     Removed Old Configuration                     ==="
fi

count=$(grep -c '/jci/gui/addon-common/websocketd --port=9998 sh' /jci/scripts/stage_wifi.sh)
if [ "$count" = "0" ]
	then
		#echo -e '\n\n\n### Video player' >> /jci/scripts/stage_wifi.sh
		#echo -e '\n/jci/gui/addon-common/websocketd --port=9998 sh &' >> /jci/scripts/stage_wifi.sh
    sed -i '/#!/ a\### Video player' /jci/scripts/stage_wifi.sh
    sleep 1
    sed -i '/Video player/ i\ ' /jci/scripts/stage_wifi.sh
    sed -i '/Video player/ a\/jci/gui/addon-common/websocketd --port=9998 sh &' /jci/scripts/stage_wifi.sh
    chmod 755 /jci/scripts/stage_wifi.sh
    log_message "===                      Modified Stage_wifi.sh                       ==="
fi

# Call to the function to populate the json
add_app_json "_videoplayer" "Video Player"

cp -a ${MYDIR}/config/videoplayer/jci/gui/apps/* /jci/gui/apps/
chmod 755 -R /jci/gui/apps/_videoplayer/

log_message "===                       Copy VideoPlayer Files                      ==="


cp -a ${MYDIR}/config/videoplayer/usr/lib/gstreamer-0.10/* /usr/lib/gstreamer-0.10/
cp -a ${MYDIR}/config/videoplayer/usr/lib/libFLAC.so.8.3.0 /usr/lib/
chmod 755 -R /usr/lib/gstreamer-0.10/libgstautodetect.so
chmod 755 -R /usr/lib/gstreamer-0.10/libgstflac.so
chmod 755 -R /usr/lib/libFLAC.so.8.3.0
ln -s /usr/lib/libFLAC.so.8.3.0 /usr/lib/libFLAC.so.8
log_message "===                Copy libs to usr/lib/gstreamer-0.10                ==="


count=$(grep -c '/imx-mm/video-codec' /etc/profile)
if [ "$count" = "0" ]
	then
		sed -i 's/\/imx-mm\/parser/\/imx-mm\/parser:\/usr\/lib\/imx-mm\/video-codec/g' /etc/profile
    log_message "===                       Fix exports / codecs                        ==="
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/imx-mm/video-codec

rm -f /tmp/root/.gstreamer-0.10/registry.arm.bin
/usr/bin/gst-inspect
log_message "===                     Updated gstreamer registry                    ==="

# patch systemApp.js if needed for v59+ app list
if ! grep -Fq "_videoplayer" /jci/gui/apps/system/js/systemApp.js && [ ${APP_PATCH_59} -eq 0 ]
then
  APP_PATCH_59=1
  cp ${MYDIR}/config/patch59/systemApp.js /jci/gui/apps/system/js/
  log_message "===                  Applied App List Patch For V59+                  ==="
fi

log_message "==========********** END INSTALLATION OF VIDEOPLAYER **********=========="
log_message " "

log_message " "
sleep 2
log_message "======================= END OF TWEAKS INSTALLATION ======================"
show_message "========== END OF TWEAKS INSTALLATION =========="
if [ "${KEEPBKUPS}" = "1" ]
then
  json="$(cat ${MYDIR}/AIO_info.json)"
  rownend=$(echo -n $json | tail -c 1)
  if [ "$rownend" = "," ]
  then
    # if so, remove "," from back end
    echo -n ${json%,*} > ${MYDIR}/AIO_info.json
    sleep 2
  fi
  aio_info ']}'
fi
# a window will appear before the system reboots automatically
sleep 3
killall jci-dialog
/jci/tools/jci-dialog --info --title="SELECTED AIO TWEAKS APPLIED" --text="THE SYSTEM WILL REBOOT IN A FEW SECONDS!" --no-cancel &
sleep 10
killall jci-dialog
/jci/tools/jci-dialog --info --title="MZD-AIO-TI v.${AIO_VER}" --text="YOU CAN REMOVE THE USB DRIVE NOW\n\nENJOY!" --no-cancel &
reboot
killall jci-dialog

