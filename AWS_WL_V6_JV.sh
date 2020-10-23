#!/bin/bash
#############################################################################################
# Parameter
NVMe_Seq_PreCondition_Loops=1;
NVMe_Seq_PreCondition_Loops=1;
Block_Align=4k;

#Run_Time=1m;
Ramp_Time=30s;
Consistency_Time=30;
Alp=(A B C D E F G H I J K L);
Physical_Memsize=7000000;
Special_Test=0;
Spec_Test=0;
Customized_Test=0
Dash_Line="#################################################################################"
#############################################################################################

# Start Execution Time Check
declare -i start_time;
declare -i end_time;
declare -i elapsed_time;
declare -i hour;
declare -i minute;
declare -i htime;
declare -i mtime;
declare -i stime;

start_time=$(date +%s);
start_time_string=$(date);
hour=3600;
minute=60;

Execution_Time_Check()
{
	end_time=$(date +%s);
	end_time_string=$(date);
	elapsed_time=${end_time}-${start_time}
	htime=${elapsed_time}/${hour}
	mtime=${elapsed_time}/60-${htime}*60
	stime=${elapsed_time}-${elapsed_time}/60*60
	echo "$Dash_Line"
	echo "Execution Time is saved in execution_time.txt"
	echo -e " Interface: ${Interface}, Port: ${Port}, Block_Align: ${Block_Align} Test \n Start time : $start_time_string\n End time : $end_time_string\n Total time : ${htime}H ${mtime}M ${stime}S" > excecution_time.txt
	echo "$Dash_Line"
}


#############################################################################################


# Link Speed Check

Link_Speed_Check()
{
#	Interface=$1;
#	if [ "$Interface" = "SATA" ]
#	then
#		dmesg | grep -i sata | grep 'link up' > SATA_Link_Speed.txt;
#		echo "$Dash_Line"
#		echo -n -e "Please chek the link speed: \n$Link_Speed\n";
#		echo "Please type yes(y) or no(n))";
#		read check_yes_no;
#		if [ "$check_yes_no" = "yes" ] || [ "$check_yes_no" = "y" ]
#		then
#			ehco ""
#		elif ["$check_yes_no" = "no" ] || [ "$check_yes_no" = "n" ]
#		then
#			echo "Stop"
#			exit 1
#		else
#			echo "Unrecognized value"
#			exit 1
#		fi
#	elif [ "$Interface" = "SAS" ]
#	then
#		cat /sys/class/sas_phy/phy-0:?/negotiated_linkrate | grep 'Gbit' > SCSI_Link_Speed.txt;
#		Link_Speed=$(cat SCSI_Link_Speed.txt);
#		echo "$Dash_line"
#		echo -n -e "Please chek the link speed: \n$Link_Speed\n";
#		echo "Please type yes(y) or no(n))";
#		read check_yes_no;
#		if [ "$check_yes_no" = "yes" ] || [ "$check_yes_no" = "y" ]
#		then
#			ehco ""
#		elif ["$check_yes_no" = "no" ] || [ "$check_yes_no" = "n" ]
#		then
#			echo "Stop"
#			exit 1
#		else
#			echo "Unrecognized value"
#			exit 1
#		fi
#	elif [ "$Interface" = "NVMe" ]
#	if [ "$Interface" = "NVMe" ]
#	then
		lspci -vv > PCIe_Device.txt;
		cat PCIe_Device.txt | grep -F 'Non-Volitale memory controller' -A 30 > NVMe_Controller.txt;
		cat NVMe_Controller.txt | grep -i 'LinSta' > Link_Speed.txt;
		cat Link_Speed.txt | cut -c 2-32 > PCIe_Link_Speed.txt;
		echo "$Dash_line"
		echo -n -e "Please chek the link speed: \n$Link_Speed\n";
		echo "Please type yes(y) or no(n))";
		read check_yes_no;
		if [ "$check_yes_no" = "yes" ] || [ "$check_yes_no" = "y" ]
		then
			echo ""
		elif ["$check_yes_no" = "no" ] || [ "$check_yes_no" = "n" ]
		then
			echo "Stop"
			exit 1
		else
			echo "Unrecognized value"
			exit 1
		fi
#	fi
	echo "$Dash_Line"
}

# Physical memory check. If the physical memory is lower than 8GB, the script will be terminated.
# Memory check
while IFS=":" read -r temp memsize
do
	case "$temp" in
		MemTotal*) phymem="$memsize"
	esac
done <"/proc/meminfo"

if [[ ${phymem%kB} -ge $Physical_Memsize ]]
then
	echo "$Dash_Line"
	echo "Physical memory: $phymem is OK";
	echo "$Dash_Line"
else
	echo "$Dash_Line"
	echo "Warning: System memory is lower than 8GB."
	echo "$Dash_Line"
exit
fi

# Delete Previous Results
#\rm filesize;
#\rm raid_check;
#\rm *.txt;
#\rm *~;
#\rm *pre*;
#echo "Remove result files?"
#\rm -I *Wor*;
\rm 32K*;
\rm 4K*;
echo "The previous results are deleted";


# Target Device Select
Device_Select()
{
	echo "Please enter the NVMe device path: ex) nvme0n1"
	read devpath1;
	FILENAME1=/dev/$devpath1;
	echo "Target NVMe device path is $FILENAME1";
}

# Input Running Time
Running_Time()
{
	echo "Please enter how long to run the selected target WL in seconds?";
	read running_time;
	Run_Time=$running_time;
	echo "The Running Time is $Run_Time seconds";
}


# Get Target Device Information
Device_Information()
{
	if [ -x "./smartctl" ]
	then
		echo "$Dash_Line"
		echo "Device Information was saved in disk_info.txt"
		echo "$Dash_Line"
		echo -e ""
		./smartctl -x /dev/$devpath1> disk_info.txt
	else
		echo -e -n "SMARTMOONTOOLS is needed for getting system information to run the test\n"
		exit
	fi
	
	# Firmware version check
	FirmWareVesrion=$(nvme fw-log /dev/$devpath1 | grep "frs")
	echo $FirmWareVersion > FimrWareVersion.txt
	echo "$Dash_Line"
	echo "Please Cehck the FW version : $FirmWareVersion"
	echo "(Please type yes(y) or no(n))";
	read check_yes_no;
	if [ "$check_yes_no" = "yes" ] || [ "$check_yes_no" = "y" ]
	then
		echo ""
	elif ["$check_yes_no" = "no" ] || [ "$check_yes_no" = "n" ]
	then
		echo "Stop"
		exit 1
	else
		echo "Unrecognized value"
		exit 1
	fi
	echo "$Dash_line"
}


# Select Target Workload
Target_WL_Select()
{
	echo "$Dash_Line";
	echo "Please select the Target WL";
	echo "$Dash_Line";
	select TargetWL in "32K SW(QD64)" "32K SR(QD32)" "4K RW(QD64)" "4K RR(QD32)" "50/50 4K Mix(QD64)" "75/25 4K Mix(QD64)" "25/75 4K Mix(QD64)";
	do
		if [ "$TargetWL" = "32K SW(QD64)" ]
		then
		fio --output=32K_SW --name=32K_SW --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=32k --rw=write --iodepth=64 --numjobs=1 --overwrite=1 --ba=4k;
		break;

	elif [ "$TargetWL" = "32K SR(QD32)" ]
	then
		fio --output=32K_SR --name=32K_SR --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=32k --rw=read --iodepth=32 --numjobs=1 --overwrite=1 --ba=4k;
		break;

	elif [ "$TargetWL" = "4K RW(QD64)" ]
	then
		fio --output=4K_RW --name=4K_RW --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=4k --rw=randwrite --iodepth=64 --numjobs=8 --overwrite=1 --ba=4k;
		break;

	elif [ "$TargetWL" = "4K RR(QD32)" ]
	then
		fio --output=4K_RR --name=4K_RR --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=4k --rw=randread --iodepth=32 --numjobs=8 --overwrite=1 --ba=4k;
		break;

	elif [ "$TargetWL" = "50/50 4K Mix(QD64)" ]
	then
		fio --output=4K_Mix_50 --name=4K_Mix_50 --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=4k --rw=randrw --rwmixwrite=50 --iodepth=64 --numjobs=8 --overwrite=1 --ba=4k;
		break;

	elif [ "$TargetWL" = "75/25 4K Mix(QD64)" ]
	then
		fio --output=4K_Mix_25 --name=4K_Mix_25 --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=4k --rw=randrw --rwmixwrite=25 --iodepth=64 --numjobs=8 --overwrite=1 --ba=4k;
		break;

	else [ "$TargetWL" = "25/75 4K Mix(QD64)" ]
		fio --output=4K_Mix_75 --name=4K_Mix_75 --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=4k --rw=randrw --rwmixwrite=75 --iodepth=64 --numjobs=8 --overwrite=1 --ba=4k;
		exit 1

		fi
	done
}


# Start Script

echo "$Dash_Line";
echo "Start AWS SSD Workload for V6 JV";
echo "$Dash_Line";
Device_Select;
echo "$Dash_Line";
Running_Time;
Target_WL_Select;

echo ""
echo "The selected workload : $TargetWL finished";
echo "$Dash_Line";

# End Sript



















































