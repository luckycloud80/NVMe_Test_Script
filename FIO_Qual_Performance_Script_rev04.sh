#!/bin/bash
###############################################################################
# Unified Script for Qualification (SATA/SAS/PCIe) Ver 1.4
# Script name: FIO_Qual_Performance_Script
# Create Date: 2015.10.01
# Author: phoenix.kim@samsung.com (Jayden Kim)
# Revision History: 
#  1. 2015.05.08 initial release 
#  2. 2015.05.13 Simplied version is added
#     - SATA/SAS Sequential_Block_Size=(512 1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1024k) 
#       --> SATA/SAS Sequential_Block_Size=(64k 128k)   
#     - SATA/SAS Random_Block_Size=(512 1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1024k) 
#       --> SATA/SAS Random_Block_Size=(4k 8k)   
#     - SATA/SAS Queue_Depth=(1 2 4 8 16 32 64 128 256 512 1024) 
#       --> SATA/SAS Queue_Depth=(1 2 4 8 16 32 64 128 256)   
#     - NVMe Sequential_Block_Size=(512 4k 8k 64k 128k) 
#       --> NVMe Sequential_Block_Size=(64k 128k)   
#     - NVMe Random_Block_Size=(512 4k 8k 64k 128k) 
#       --> NVMe Random_Block_Size=(4k 8k)   
#     - NVMe Queue_Depth=(1 2 4 8 16 32 64 128 256 512 1024) 
#       --> NVMe Queue_Depth=(1 2 4 8 16 32 64 128 256)     
#  3. 2015.07.09 Spec version is added
#     - SATA  Sequential_Block_Size=(4k 128k)
#     - SATA  Sequential_Queue_Depth=(1 32)
#     - SATA  Random_Block_Size=(4k 8k)
#     - SATA  Random_Queue_Depth=(1 32)
#     -	SATA_Random_Queue_Depth_Consistency=(1 128)
#     -	SATA_Random_Worker_Consistency=1
#     -	SAS_Sequential_Block_Size=(4k 128k)
#     -	SAS_Sequential_Queue_Depth=(1 64)
#     -	SAS_Sequential_Worker=1
#     -	SAS_Random_Block_Size=(4k 8k)
#     -	SAS_Random_Queue_Depth=(1 64)
#     -	SAS_Random_Worker=1
#     -	SAS_Random_Queue_Depth_Consistency=(1 128)
#     -	SAS_Random_Worker_Consistency=1
#     -	PCIe_Sequential_Block_Size=(4k 128k)
#     -	PCIe_Sequential_Queue_Depth=(1 16 32)
#     -	PCIe_Sequential_Worker=(1 16)
#     -	PCIe_Random_Block_Size=(4k 8k)
#     -	PCIe_Random_Queue_Depth=(1 16 32)
#     -	PCIe_Random_Worker=(1 16)
#     -	PCIe_Random_Queue_Depth_Consistency=128
#     -	PCIe_Random_Worker_Consistency=(1 16)
#  4. 2015.07.22 
#     - Link Speed Check is added
#     - Customized Version is added
#  5. 2015.10.01 
#     - NVMe Firmware version check is added
#     - Sequential ramp up time is added
###############################################################################



###############################################################################
# Parameter
SATA_Seq_PreCondition_Loops=1;
SATA_Ran_PreCondition_Loops=1;
SAS_Seq_PreCondition_Loops=1;
SAS_Ran_PreCondition_Loops=1;
PCIe_Seq_PreCondition_Loops=2;
PCIe_Ran_PreCondition_Loops=2;
Block_Align=4k;

Run_Time=1m;
Ramp_Time=30s;
Consistency_Time=30m;
Alp=(A B C D E F G H I J K L);
Physical_Memsize=7000000;
Special_Test=0;
Spec_Test=0;
Customized_Test=0;
Dash_Line="##################################################"

###############################################################################

# Execution Time check Start
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
	echo -e " Interface: ${Interface}, Port: ${Port}, Block_Align: ${Block_Align} Test \n Start time : $start_time_string\n End time : $end_time_string\n Total time : ${htime}H ${mtime}M ${stime}S" > execution_time.txt
	echo "$Dash_Line"
}

###############################################################################

# Link Speed Check

Link_Speed_Check()
{
	Interface=$1;
	if [ "$Interface" = "SATA" ]
	then
		dmesg | grep -i sata | grep 'link up' > SATA_Link_Speed.txt;
		Link_Speed=$(cat SATA_Link_Speed.txt);
		echo "$Dash_Line"
		echo -n -e "Please check the Link speed: \n$Link_Speed\n";
		echo "(Please type yes(y) or no(n))";
		read check_yes_no;
		if [ "$check_yes_no" = "yes" ] || [ "$check_yes_no" = "y" ]
		then
			echo ""
		elif [ "$check_yes_no" = "no" ] || [ "$check_yes_no" = "n" ]
		then
			echo "Stop"
			exit 1
		else
			echo "Unrecognized value."
			exit 1
		fi
	elif [ "$Interface" = "SAS" ]
	then
		cat /sys/class/sas_phy/phy-0:?/negotiated_linkrate | grep 'Gbit' > SCSI_Link_Speed.txt;
		Link_Speed=$(cat SCSI_Link_Speed.txt); 
		echo "$Dash_Line"
		echo -n -e "Please check the Link speed: \n$Link_Speed\n";
		echo "(Please type yes(y) or no(n))";
		read check_yes_no;
		if [ "$check_yes_no" = "yes" ] || [ "$check_yes_no" = "y" ]
		then
			echo ""
		elif [ "$check_yes_no" = "no" ] || [ "$check_yes_no" = "n" ]
		then
			echo "Stop"
			exit 1
		else
			echo "Unrecognized value."
			exit 1
		fi		
	elif [ "$Interface" = "PCIe" ]
	then
		lspci -vv > PCIe_Device.txt;
		cat PCIe_Device.txt | grep -F 'Non-Volatile memory controller' -A 30 > PCIe_NVM_Controller.txt;
		cat PCIe_NVM_Controller.txt | grep -i 'LnkSta' > Link_Speed.txt;
		cat Link_Speed.txt | cut -c 2-32  > PCIe_Link_Speed.txt;
		Link_Speed=$(cat PCIe_Link_Speed.txt);
		echo "$Dash_Line"
		echo "Please check the Link speed: $Link_Speed";
		echo "(Please type yes(y) or no(n))";
		read check_yes_no;
		if [ "$check_yes_no" = "yes" ] || [ "$check_yes_no" = "y" ]
		then
			echo ""
		elif [ "$check_yes_no" = "no" ] || [ "$check_yes_no" = "n" ]
		then
			echo "Stop"
			exit 1
		else
			echo "Unrecognized value."
			exit 1
		fi
	elif [ "$Interface" = "Customized" ]
	then
		echo "Link speed check is skipped";
	fi
	echo "$Dash_Line"
}

# Physical memory check. If physical memory is lower than 8GB, script will be terminated.
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

# Gabage Data Clear
\rm filesize;
\rm raid_check;
\rm *.txt;
\rm *~;
\rm *pre*;
echo "Remove result files?"
rm -I *Wor*;
echo "Gabage data is cleared";

# Device Select
Device_Select_Single_Port()
{ 
	if [ "$Special_Test" = 0 ]
	then
		echo "Enter the device path: ex) sda"
		read devpath1;
		FILENAME1=/dev/$devpath1;
		echo "devpath is $FILENAME1";
	elif [ "$Special_Test" = 1 ]
	then
		FILENAME1=$RAIDDEVICEPATH;
		echo "Test device is $FILENAME1"
	else
		echo "Unrecognized value."
	exit 1
	fi
	
}
Device_Select_Dual_Port()
{
	echo "Enter the 1st device path:: ex) sda";
	read devpath1;
	FILENAME1=/dev/$devpath1;
	echo "Enter the 2nd device path: ex) sdb";
	read devpath2;
	FILENAME2=/dev/$devpath2;
	echo "devpath is 1st: /dev/$devpath1 2nd: /dev/$devpath2";
}

# Get Device Information 
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
	if [ "$Interface" = "PCIe" ]
	then
	FirmWareVersion=$(nvme fw-log /dev/$devpath1 | grep "frs")
	elif [ "$Interface" = "SATA" ]
	then
	FirmWareVersion=$(cat ./disk_info.txt | grep "Firmware Version")
	else
		echo ""
	fi
	echo $FirmWareVersion > FirmWareVersion.txt
	echo "$Dash_Line"
	echo "Please Check the FW version(SATA/NVMe Support): $FirmWareVersion"
	echo "(Please type yes(y) or no(n))";
	read check_yes_no;
	if [ "$check_yes_no" = "yes" ] || [ "$check_yes_no" = "y" ]
	then
		echo ""
	elif [ "$check_yes_no" = "no" ] || [ "$check_yes_no" = "n" ]
	then
		echo "Stop"
		exit 1
	else
		echo "Unrecognized value."
		exit 1
	fi
	echo "$Dash_Line"
}

# System Config Check
System_Config()
{
	CPU=$(cat /proc/cpuinfo | grep "model name" | head -1 | awk '{print $4$7}')
	CPUFREQ=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')
	CPUCORES=$(cat /proc/cpuinfo | grep "cpu cores" | head -1 | awk '{print $4}')
	CPUSIBLINGS=$(cat /proc/cpuinfo | grep "siblings" | head -1 | awk '{print $3}')
	let "CPUCOUNT=($((`cat /proc/cpuinfo | grep processor | tail -1 | awk {'print $3'}`))+1)/$CPUSIBLINGS"
	MACHINE=`uname -n`
	KERNEL=`uname -r`
	KERNELPARAMS=`cat /proc/cmdline`
	VERSION=$(cat /etc/redhat-release | grep "Red") 
	DRIVEBASE=$(basename /dev/$devpath1)
	DRIVESIZEBYTES=$(($(cat /sys/block/$DRIVEBASE/size) *512))
	DRIVESIZEGB=$(($DRIVESIZEBYTES/1000000000))
	DRIVESIZEGiB=$(($DRIVESIZEBYTES/1024/1024/1024))
	DRIVESIZEBYTES_OFFSET=$(($DRIVESIZEBYTES/2)) #For FIO Offset
	MEMORYSIZE=$(cat /proc/meminfo | grep "MemTotal" | head -1 | awk '{print $2}')
	MEMORYSIZEGB=$(($MEMORYSIZE/1000000))
	echo -e " CPU Model: $CPU, CPU Frequency: $CPUFREQ, CPU Cores: $CPUCORES, CPU Count: $CPUCOUNT\n KERNAL Version: $KERNEL\n Linux Version: $VERSION\n Memory: ${MEMORYSIZEGB}GB \n" > system_info.txt
	echo "$Dash_Line"
	echo "Device Information was saved in system_info.txt"
	echo "$Dash_Line"
	echo -e ""
}

# Block Align Select
Block_Align_Select()
{
	echo "$Dash_Line";
	echo "Please Select the Block Align";
	echo "$Dash_Line";
	select blockalign in "512B" "4KB" "8KB";
	do
	if [ "$blockalign" = "512B" ]
	then
		Block_Align=512;
	break;
	elif [ "$blockalign" = "4KB" ]
	then
		Block_Align=4k;
	break;
	elif [ "$blockalign" = "8KB" ]
	then
		Block_Align=8k;
	break;
	else
		echo "Unrecognized value."
	exit 1
	fi
	done
}

# Test Level Select
Test_Level_Select()
{
	echo "$Dash_Line";
	echo "Please Select the Test Level";
	echo "$Dash_Line";
	select testlevel in "Spec Version" "Simplified Version" "Advanced Version" "Customized Version";
	do
	if [ "$testlevel" = "Spec Version" ]
	then
	Spec_Test=1;
	SATA_Sequential_Block_Size=128k;
	SATA_Sequential_Queue_Depth=(1 32);
	SATA_Sequential_Worker=1;
	SATA_Random_Block_Size=4k;
	SATA_Random_Queue_Depth=(1 32);
	SATA_Random_Worker=1;
	SATA_Random_Block_Size_Consistency=4K;
	SATA_Random_Queue_Depth_Consistency=(1 32);
	SATA_Random_Worker_Consistency=1;
	SAS_Sequential_Block_Size=128k;
	SAS_Sequential_Queue_Depth=(1 64 128);
	SAS_Sequential_Worker=1;
	SAS_Random_Block_Size=(4k 8k);
	SAS_Random_Queue_Depth=(1 64 128);
	SAS_Random_Worker=1;
	SAS_Random_Block_Size_Consistency=(4K 8K);
	SAS_Random_Queue_Depth_Consistency=(1 128);
	SAS_Random_Worker_Consistency=1;
	PCIe_Sequential_Block_Size=128k;
	PCIe_Sequential_Queue_Depth=(1 16 32);
	PCIe_Sequential_Worker=(1 16);
	PCIe_Random_Block_Size=(4k 8k);
	PCIe_Random_Queue_Depth=(1 16 32);
	PCIe_Random_Worker=(1 16);
	PCIe_Random_Block_Size_Consistency=(4K 8K);
	PCIe_Random_Queue_Depth_Consistency=(1 128);
	PCIe_Random_Worker_Consistency=(1 16);
	break;
	elif [ "$testlevel" = "Simplified Version" ]
	then
	SATA_Sequential_Block_Size=(64k 128k);
	SATA_Sequential_Queue_Depth=(1 2 4 8 16 32 64 128 256);
	SATA_Sequential_Worker=1;
	SATA_Random_Block_Size=(4k 8k);
	SATA_Random_Queue_Depth=(1 2 4 8 16 32 64 128 256);
	SATA_Random_Worker=1;
	SATA_Random_Queue_Depth_Consistency=(1 128);
	SATA_Random_Worker_Consistency=1;
	SAS_Sequential_Block_Size=(64k 128k);
	SAS_Sequential_Queue_Depth=(1 2 4 8 16 32 64 128 256);
	SAS_Sequential_Worker=1;
	SAS_Random_Block_Size=(4k 8k);
	SAS_Random_Queue_Depth=(1 2 4 8 16 32 64 128 256);
	SAS_Random_Worker=1;
	SAS_Random_Queue_Depth_Consistency=(1 128);
	SAS_Random_Worker_Consistency=1;
	PCIe_Sequential_Block_Size=(4k 64k 128k);
	PCIe_Sequential_Queue_Depth=(1 2 4 8 16 32 64 128 256);
	PCIe_Sequential_Worker=(1 2 4 8 16 32 64);
	PCIe_Random_Block_Size=(4k 8k);
	PCIe_Random_Queue_Depth=(1 2 4 8 16 32 64 128 256);
	PCIe_Random_Worker=(1 2 4 8 16 32 64);
	PCIe_Random_Queue_Depth_Consistency=(1 128);
	PCIe_Random_Worker_Consistency=(1 16);
	break;
	elif [ "$testlevel" = "Advanced Version" ]
	then
	SATA_Sequential_Block_Size=(512 1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1024k);
	SATA_Sequential_Queue_Depth=(1 2 4 8 16 32 64 128 256 512 1024);
	SATA_Sequential_Worker=1;
	SATA_Sequential_Queue_Depth_Consistency=(1 32);
	SATA_Sequential_Worker_Consistency=1;
	SATA_Random_Block_Size=(512 1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1024k);
	SATA_Random_Queue_Depth=(1 2 4 8 16 32 64 128 256 512 1024);
	SATA_Random_Worker=1;
	SATA_Random_Queue_Depth_Consistency=(1 32);
	SATA_Random_Worker_Consistency=1;
	SAS_Sequential_Block_Size=(512 1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1024k);
	SAS_Sequential_Queue_Depth=(1 2 4 8 16 32 64 128 256 512 1024);
	SAS_Sequential_Worker=1;
	SAS_Sequential_Queue_Depth_Consistency=(1 128);
	SAS_Sequential_Worker_Consistency=1;
	SAS_Random_Block_Size=(512 1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1024k);
	SAS_Random_Queue_Depth=(1 2 4 8 16 32 64 128 256 512 1024);
	SAS_Random_Worker=1;
	SAS_Random_Queue_Depth_Consistency=(1 128);
	SAS_Random_Worker_Consistency=1;
	PCIe_Sequential_Block_Size=(512 4k 8k 64k 128k);
	PCIe_Sequential_Queue_Depth=(1 2 4 8 16 32 64 128 256 512 1024);
	PCIe_Sequential_Worker=(1 2 4 8 16 32 64);
	PCIe_Sequential_Queue_Depth_Consistency=(1 128);
	PCIe_Sequential_Worker_Consistency=(1 16);
	PCIe_Random_Block_Size=(512 4k 8k 64k 128k);
	PCIe_Random_Queue_Depth=(1 2 4 8 16 32 64 128 256 512 1024);
	PCIe_Random_Worker=(1 2 4 8 16 32 64);
	PCIe_Random_Queue_Depth_Consistency=(1 128);
	PCIe_Random_Worker_Consistency=(1 16);
	break;
	elif [ "$testlevel" = "Customized Version" ]
	then
	Customized_Test=1;
	echo "Please type the sequential precondition loop: ex) 1";
	read Seq_PreCondition_Loops;
	Customized_Seq_PreCondition_Loops=$Seq_PreCondition_Loops;
	echo "Please type the sequential block size: ex) 64K 128K";
	read Seq_Block_Size;
	Customized_Sequential_Block_Size=$Seq_Block_Size;
	echo "Please type the sequential queue depth: ex) 1 16 32";
	read Seq_Queue_Depth;
	Customized_Sequential_Queue_Depth=$Seq_Queue_Depth;
	echo "Please type the sequential worker: ex) 1 2 4";
	read Seq_Worker;
	Customized_Sequential_Worker=$Seq_Worker;
	echo "Please type the sequential queue depth for consistency: ex) 1 128";
	read Seq_Queue_Depth_Consistency;
	Customized_Sequential_Queue_Depth_Consistency=$Seq_Queue_Depth_Consistency;
	echo "Please type the sequential worker for consistency: ex) 1 16";
	read Seq_Worker_Consistency;
	Customized_Sequential_Worker_Consistency=$Seq_Worker_Consistency;
	echo "Please type the random precondition loop: ex) 1";
	read Ran_PreCondition_Loops;
	Customized_Ran_PreCondition_Loops=$Ran_PreCondition_Loops;
	echo "Please type the random block size: ex) 4K 8K";
	read Ran_Block_Size;
	Customized_Random_Block_Size=$Ran_Block_Size;
	echo "Please type the random queue depth: ex) 1 16 32";
	read Ran_Queue_Depth;
	Customized_Random_Queue_Depth=$Ran_Queue_Depth;
	echo "Please type the random worker: ex) 1 2 4";
	read Ran_Worker;
	Customized_Random_Worker=$Ran_Worker;
	echo "Please type the random queue depth for consistency: ex) 1 128";
	read Ran_Queue_Depth_Consistency;
	Customized_Random_Queue_Depth_Consistency=$Ran_Queue_Depth_Consistency;
	echo "Please type the random worker for consistency: ex) 1 16";
	read Ran_Worker_Consistency;
	Customized_Random_Worker_Consistency=$Ran_Worker_Consistency;
	break;
	else
		echo "Unrecognized value."
	exit 1
	fi
	done
}

# Test Function 

Sequential_Precondition()
{
	Interface=$1;
	Port=$2;
	echo "Sequential_Precondition, Interface=$1, Port=$2"
	if [ "$Interface" = "SATA" ]
	then
		Seq_PreLoops=$SATA_Seq_PreCondition_Loops;
	elif [ "$Interface" = "SAS" ]
	then
		Seq_PreLoops=$SAS_Seq_PreCondition_Loops;
	elif [ "$Interface" = "PCIe" ]
	then
		Seq_PreLoops=$PCIe_Seq_PreCondition_Loops;
	elif [ "$Interface" = "Customized" ]
	then
		Seq_PreLoops=$Customized_Seq_PreCondition_Loops;
	else
		echo "Unrecognized value."
	fi
	if [ "$Port" = "Single" ]
	then
		fio --output=1_pre128kw100q32 --name=1_pre128kw100q32 --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --loops=$Seq_PreLoops --size=100% --blocksize=128k --rw=write --iodepth=32 --overwrite=1 --ba=4k;
	elif [ "$Port" = "Dual" ]
	then
		fio --name=global --output=1_pre128kw100q32 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --loops=$Seq_PreLoops --size=100% --blocksize=128k --rw=write --iodepth=32 --overwrite=1 --ba=4k --name=1_pre128kw100q32 --filename=$FILENAME1 --name=2_pre128kw100q32 --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
	else
		echo "Unrecognized value."
	fi
}

Sequential_Read()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		BS=${SATA_Sequential_Block_Size[*]};
		QD=${SATA_Sequential_Queue_Depth[*]};
		WK=${SATA_Sequential_Worker[*]};
	elif [ "$Interface" = "SAS" ]
	then
		BS=${SAS_Sequential_Block_Size[*]};
		QD=${SAS_Sequential_Queue_Depth[*]};
		WK=${SAS_Sequential_Worker[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		BS=${PCIe_Sequential_Block_Size[*]};
		QD=${PCIe_Sequential_Queue_Depth[*]};
		WK=${PCIe_Sequential_Worker[*]};
	elif [ "$Interface" = "Customized" ]
	then
		BS=${Customized_Sequential_Block_Size[*]};
		QD=${Customized_Sequential_Queue_Depth[*]};
		WK=${Customized_Sequential_Worker[*]};
	else
		echo "Unrecognized value."
	fi
	for Block_Size in $BS; do
		BS_Alpha=${Alp[i++]};
		for Worker in $WK; do
			WK_Alpha=${Alp[j++]};
			for QueueDepth in $QD; do
				QD_Alpha=${Alp[k++]};	
				echo "Interface = $Interface, Port = $Port, Sequential_Read, Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
				if [ "$Port" = "Single" ]
				then
					fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=read --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
				elif [ "$Port" = "Dual" ]
				then
					fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=read --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD$QueueDepth --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
				else
					echo "Unrecognized value."
				fi
			done;
			k=0;
		done;
		j=0;
	done
	i=0;
}

Sequential_Read_Consistency()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		QD=${SATA_Sequential_Queue_Depth_Consistency[*]};
		WK=${SATA_Sequential_Worker_Consistency[*]};
	elif [ "$Interface" = "SAS" ]
	then
		QD=${SAS_Sequential_Queue_Depth_Consistency[*]};
		WK=${SAS_Sequential_Worker_Consistency[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		QD=${PCIe_Sequential_Queue_Depth_Consistency[*]};
		WK=${PCIe_Sequential_Worker_Consistency[*]};
	elif [ "$Interface" = "Customized" ]
	then
		QD=${Customized_Sequential_Queue_Depth_Consistency[*]};
		WK=${Customized_Sequential_Worker_Consistency[*]};
	else
		echo "Unrecognized value."
	fi
	for Block_Size in 128k; do
		BS_Alpha=0;
		for Worker in $WK; do
			WK_Alpha=${Alp[j++]};
			for QueueDepth in $QD; do
				QD_Alpha=${Alp[k++]};
				echo "Interface = $Interface, Port = $Port, Sequential_Read_Consistency, Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
				if [ "$Port" = "Single" ]
				then
					fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Consistency_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=read --iodepth=${QueueDepth} --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
				elif [ "$Port" = "Dual" ]
				then
				fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Consistency_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=read --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency_1 --filename=$FILENAME1  --name=Worker${WK_Alpha}_${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_A_SeqWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency_2 --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
				else
					echo "Unrecognized value."
				fi
			done;
			k=0;
		done;
		j=0;
	done
	i=0;
}

Sequential_Write()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		BS=${SATA_Sequential_Block_Size[*]};
		QD=${SATA_Sequential_Queue_Depth[*]};
		WK=${SATA_Sequential_Worker[*]};
	elif [ "$Interface" = "SAS" ]
	then
		BS=${SAS_Sequential_Block_Size[*]};
		QD=${SAS_Sequential_Queue_Depth[*]};
		WK=${SAS_Sequential_Worker[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		BS=${PCIe_Sequential_Block_Size[*]};
		QD=${PCIe_Sequential_Queue_Depth[*]};
		WK=${PCIe_Sequential_Worker[*]};
	elif [ "$Interface" = "Customized" ]
	then
		BS=${Customized_Sequential_Block_Size[*]};
		QD=${Customized_Sequential_Queue_Depth[*]};
		WK=${Customized_Sequential_Worker[*]};
	else
		echo "Unrecognized value."
	fi
	for Block_Size in $BS; do
		BS_Alpha=${Alp[i++]};
		for Worker in $WK; do
			WK_Alpha=${Alp[j++]};
			for QueueDepth in $QD; do
				QD_Alpha=${Alp[k++]};
				echo "Interface = $Interface, Port = $Port, Sequential_Write, Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
			if [ "$Port" = "Single" ]
			then
				fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=write --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
			elif [ "$Port" = "Dual" ]
			then
				fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=write --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
			else
				echo "Unrecognized value."
			fi
			done;
			k=0;
		done;
		j=0;
	done
	i=0;
}

Sequential_Write_Consistency()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		QD=${SATA_Sequential_Queue_Depth_Consistency[*]};
		WK=${SATA_Sequential_Worker_Consistency[*]};
	elif [ "$Interface" = "SAS" ]
	then
		QD=${SAS_Sequential_Queue_Depth_Consistency[*]};
		WK=${SAS_Sequential_Worker_Consistency[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		QD=${PCIe_Sequential_Queue_Depth_Consistency[*]};
		WK=${PCIe_Sequential_Worker_Consistency[*]};
	elif [ "$Interface" = "Customized" ]
	then
		QD=${Customized_Sequential_Queue_Depth_Consistency[*]};
		WK=${Customized_Sequential_Worker_Consistency[*]};
	else
		echo "Unrecognized value."
	fi
	for Block_Size in $BS; do
		BS_Alpha=0;
		for Worker in $WK; do
			WK_Alpha=${Alp[j++]};
		for QueueDepth in 32; do
			QD_Alpha=${Alp[k++]};
			echo "Interface = $Interface, Port = $Port, Sequential_Write_Consistency, Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
		if [ "$Port" = "Single" ]
		then
			fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Consistency_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=write --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
		elif [ "$Port" = "Dual" ]
		then
			fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Consistency_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=write --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency_1 --filename=$FILENAME1 --name=Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_B_SeqWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency_2 --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
		else
			echo "Unrecognized value."
			fi
		done;
		k=0;
	done;
	j=0;
done
i=0;
}

Random_Precondition()
{
	Interface=$1;
	Port=$2;
	echo "Random_Precondition, Interface=$1, Port=$2"
	if [ "$Interface" = "SATA" ]
	then
		Ran_PreLoops=$SATA_Ran_PreCondition_Loops;
	elif [ "$Interface" = "SAS" ]
	then
		Ran_PreLoops=$SAS_Ran_PreCondition_Loops;
	elif [ "$Interface" = "PCIe" ]
	then
		Ran_PreLoops=$PCIe_Ran_PreCondition_Loops;
	elif [ "$Interface" = "Customized" ]
	then
		Ran_PreLoops=$Customized_Ran_PreCondition_Loops;
	else
		echo "Unrecognized value."
	fi

	if [ "$Port" = "Single" ]
	then
		fio --name=1_pre4kw100q32 --output=1_pre4kw100q32 --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --loops=$Ran_PreLoops --size=100% --blocksize=4k --rw=randwrite --iodepth=32 --overwrite=1 --ba=4k;
	elif [ "$Port" = "Dual" ]
	then
		fio --name=global --output=1_pre4kw100q32 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --loops=$Ran_PreLoops --size=100% --blocksize=4k --rw=randwrite --iodepth=32 --overwrite=1 --ba=4k --name=1_pre4kw100q32 --filename=$FILENAME1 --name=2_pre4kw100q32 --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
	else
		echo "Unrecognized value."
	fi
}

Random_Read()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		BS=${SATA_Random_Block_Size[*]};
		QD=${SATA_Random_Queue_Depth[*]};
		WK=${SATA_Random_Worker[*]};
	elif [ "$Interface" = "SAS" ]
	then
		BS=${SAS_Random_Block_Size[*]};
		QD=${SAS_Random_Queue_Depth[*]};
		WK=${SAS_Random_Worker[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		BS=${PCIe_Random_Block_Size[*]};
		QD=${PCIe_Random_Queue_Depth[*]};
		WK=${PCIe_Random_Worker[*]};
	elif [ "$Interface" = "Customized" ]
	then
		BS=${Customized_Random_Block_Size[*]};
		QD=${Customized_Random_Queue_Depth[*]};
		WK=${Customized_Random_Worker[*]};
	else
		echo "Unrecognized value."
	fi

	for Block_Size in $BS; do
		BS_Alpha=${Alp[i++]};
		for Worker in $WK; do
			WK_Alpha=${Alp[j++]};
			for QueueDepth in $QD; do
				QD_Alpha=${Alp[k++]};
				echo "Interface = $Interface, Port = $Port, Random_Read, Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
				if [ "$Port" = "Single" ]
				then
					fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randread --iodepth=${QueueDepth} --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
				elif [ "$Port" = "Dual" ]
				then
					fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randread --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
				else
					echo "Unrecognized value."
				fi
			done;
			k=0;
		done;
		j=0;
	done
	i=0;
}

Random_Read_Consistency()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		BS=${SATA_Random_Block_Size_Consistency[*]};
		QD=${SATA_Random_Queue_Depth_Consistency[*]};
		WK=${SATA_Random_Worker_Consistency[*]};
	elif [ "$Interface" = "SAS" ]
	then
		BS=${SAS_Random_Block_Size_Consistency[*]};
		QD=${SAS_Random_Queue_Depth_Consistency[*]};
		WK=${SAS_Random_Worker_Consistency[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		BS=${PCIe_Random_Block_Size_Consistency[*]};
		QD=${PCIe_Random_Queue_Depth_Consistency[*]};
		WK=${PCIe_Random_Worker_Consistency[*]};
	elif [ "$Interface" = "Customized" ]
	then
		BS=${Customized_Random_Block_Size_Consistency[*]};
		QD=${Customized_Random_Queue_Depth_Consistency[*]};
		WK=${Customized_Random_Worker_Consistency[*]};
	else
		echo "Unrecognized value."
	fi
	for Block_Size in $BS;do
		BS_Alpha=0;
		for Worker in $WK;do
			WK_Alpha=${Alp[j++]};
			for QueueDepth in $QD; do
				QD_Alpha=${Alp[k++]};
				echo "Interface = $Interface, Port = $Port, Random_Read_Consistency, Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
				if [ "$Port" = "Single" ]
				then
					fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Consistency_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randread --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
				elif [ "$Port" = "Dual" ]
				then
					fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based -runtime=$Consistency_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randread --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency_1 --filename=$FILENAME1 --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_C_RanWrite_A_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency_2 --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
				else
					echo "Unrecognized value."
				fi
			done;
			k=0;
		done;
		j=0;
	done
	i=0;
}

Random_Write()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		BS=${SATA_Random_Block_Size[*]};
		QD=${SATA_Random_Queue_Depth[*]};
		WK=${SATA_Random_Worker[*]};
	elif [ "$Interface" = "SAS" ]
	then
		BS=${SAS_Random_Block_Size[*]};
		QD=${SAS_Random_Queue_Depth[*]};
		WK=${SAS_Random_Worker[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		BS=${PCIe_Random_Block_Size[*]};
		QD=${PCIe_Random_Queue_Depth[*]};
		WK=${PCIe_Random_Worker[*]};
	elif [ "$Interface" = "Customized" ]
	then
		BS=${Customized_Random_Block_Size[*]};
		QD=${Customized_Random_Queue_Depth[*]};
		WK=${Customized_Random_Worker[*]};
	else
		echo "Unrecognized value."
	fi
	for Block_Size in $BS; do
		BS_Alpha=${Alp[i++]};
		for Worker in $WK; do
			WK_Alpha=${Alp[j++]};
			for QueueDepth in $QD; do
				QD_Alpha=${Alp[k++]};
				echo "Interface = $Interface, Port = $Port, Random_Write, Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
				if [ "$Port" = "Single" ]
				then
					fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randwrite --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
				elif [ "$Port" = "Dual" ]
				then
					fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randwrite --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
				else
					echo "Unrecognized value."
				fi
			done;
			k=0;
		done;
		j=0;
	done
	i=0;
}

Random_Write_Consistency()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		BS=${SATA_Random_Block_Size_Consistency[*]};
		QD=${SATA_Random_Queue_Depth_Consistency[*]};
		WK=${SATA_Random_Worker_Consistency[*]};
	elif [ "$Interface" = "SAS" ]
	then
		BS=${SAS_Random_Block_Size_Consistency[*]};
		QD=${SAS_Random_Queue_Depth_Consistency[*]};
		WK=${SAS_Random_Worker_Consistency[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		BS=${PCIe_Random_Block_Size_Consistency[*]};
		QD=${PCIe_Random_Queue_Depth_Consistency[*]};
		WK=${PCIe_Random_Worker_Consistency[*]};
	elif [ "$Interface" = "Customized" ]
	then
		BS=${Customized_Random_Block_Size_Consistency[*]};
		QD=${Customized_Random_Queue_Depth_Consistency[*]};
		WK=${Customized_Random_Worker_Consistency[*]};
	else
		echo "Unrecognized value."
	fi
	for Block_Size in $BS;do
		BS_Alpha=0;
		for Worker in $WK;do
			WK_Alpha=${Alp[j++]};
			for QueueDepth in $QD; do
				QD_Alpha=${Alp[k++]};
				echo "Interface = $Interface, Port = $Port, Random_Write_Consistency, Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
				if [ "$Port" = "Single" ]
				then
					fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Consistency_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randwrite --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
				elif [ "$Port" = "Dual" ]
				then
					fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Consistency_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randwrite --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --filename=$FILENAME1 --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency_1 --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency --filename=$FILENAME2 --write_iops_log=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_E_RanWrite_E_${WritePotion}_${QD_Alpha}_QD${QueueDepth}_Consistency_2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
				else
					echo "Unrecognized value."
				fi
			done;
			k=0;
		done;
		j=0;
	done
	i=0;
}

Random_Mixed()
{
	Interface=$1;
	Port=$2;
	WritePotion=$3;
	i=0;
	j=0;
	k=0;
	if [ "$Interface" = "SATA" ]
	then
		BS=${SATA_Random_Block_Size[*]};
		QD=${SATA_Random_Queue_Depth[*]};
		WK=${SATA_Random_Worker[*]};
	elif [ "$Interface" = "SAS" ]
	then
		BS=${SAS_Random_Block_Size[*]};
		QD=${SAS_Random_Queue_Depth[*]};
		WK=${SAS_Random_Worker[*]};
	elif [ "$Interface" = "PCIe" ]
	then
		BS=${PCIe_Random_Block_Size[*]};
		QD=${PCIe_Random_Queue_Depth[*]};
		WK=${PCIe_Random_Worker[*]};
	elif [ "$Interface" = "Customized" ]
	then
		BS=${Customized_Random_Block_Size[*]};
		QD=${Customized_Random_Queue_Depth[*]};
		WK=${Customized_Random_Worker[*]};
	else
		echo "Unrecognized value."
	fi
	if [ "$WritePotion" = "30" ]
	then
		WP_Alpha=B;
	elif [ "$WritePotion" = "50" ]
	then
		WP_Alpha=C;
	elif [ "$WritePotion" = "70" ]
	then
		WP_Alpha=D;
	else
		echo "Unrecognized value."
	fi
	for Block_Size in $BS; do
		BS_Alpha=${Alp[i++]};
		for Worker in $WK; do
			WK_Alpha=${Alp[j++]};
			for QueueDepth in $QD; do
				QD_Alpha=${Alp[k++]};	
				echo "Interface = $Interface, Port = $Port, Random_Mixed = Write ${WritePotion}% Block Size = ${Block_Size}, Queue Depth = ${QueueDepth}, Worker = ${Worker}, Block Align = ${Block_Align}"
				if [ "$Port" = "Single" ]
				then
					fio --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_D_RanWrite_${WP_Alpha}_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_SinglePort_D_RanWrite_${WP_Alpha}_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randrw --rwmixwrite=$WritePotion --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker;
				elif [ "$Port" = "Dual" ]
				then
					fio --name=global --output=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort_D_RanWrite_${WP_Alpha}_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --runtime=$Run_Time --clocksource=clock_gettime --blocksize=$Block_Size --rw=randrw --rwmixwrite=$WritePotion --iodepth=$QueueDepth --ramp_time=$Ramp_Time --overwrite=1 --ba=$Block_Align --numjobs=$Worker --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort1_D_RanWrite_${WP_Alpha}_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME1 --name=${WK_Alpha}_Worker${Worker}_${BS_Alpha}_${Block_Size}_DualPort2_D_RanWrite_${WP_Alpha}_${WritePotion}_${QD_Alpha}_QD${QueueDepth} --filename=$FILENAME2 --offset_increment=$DRIVESIZEBYTES_OFFSET;
				else
					echo "Unrecognized value."
				fi
			done;
			k=0;
		done;
		j=0;
	done
	i=0;
}

# RAID 0/1/5
RAID_Select()
{
	echo "$Dash_Line"
	echo "Please Select the RAID"
	echo "$Dash_Line"
	select raid in "RAID0_SATA" "RAID1_SATA" "RAID5_SATA" "RAID0_SAS" "RAID1_SAS" "RAID5_SAS" "RAID0_PCIe" "RAID1_PCIe" "RAID5_PCIe"
	do
	if [ "$raid" = "RAID0_SATA" ]
	then
		RAIDLEVEL=0;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure SATA Single;
	break;
	elif [ "$raid" = "RAID1_SATA" ]
	then
		RAIDLEVEL=1;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure SATA Single;
	break;
	elif [ "$raid" = "RAID5_SATA" ]
	then
		RAIDLEVEL=5;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure SATA Single;
	break;
	elif [ "$raid" = "RAID0_SAS" ]
	then
		RAIDLEVEL=0;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure SAS Single;
	break;
	elif [ "$raid" = "RAID1_SAS" ]
	then
		RAIDLEVEL=1;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure SAS Single;
	break;
	elif [ "$raid" = "RAID5_SAS" ]
	then
		RAIDLEVEL=5;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure SAS Single;
	break;
	elif [ "$raid" = "RAID0_PCIe" ]
	then
		RAIDLEVEL=0;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure PCIe Single;
	break;
	elif [ "$raid" = "RAID1_PCIe" ]
	then
		RAIDLEVEL=1;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure PCIe Single;
	break;	
	elif [ "$raid" = "RAID5_PCIe" ]
	then
		RAIDLEVEL=5;
		RAID_Execution;
		RAID_Device_Check;
		Test_Procedure PCIe Single;
	break;		
	else
		echo "Unrecognized value."
	exit 1
	fi
	done
}

# RAID Execution
RAID_Execution()
{
	echo "Enter 1st device path for RAID: ex) sda";
	read raiddevpath1;
	RAIDPATH1=/dev/$raiddevpath1;
	echo "Enter 2nd device path for RAID: ex) sdb";
	read raiddevpath2;
	RAIDPATH2=/dev/$raiddevpath2;
	if [ "$RAIDLEVEL" = "0" ] || [ "$RAIDLEVEL" = "1" ]
	then
		echo "Enter RAID Device name: ex) md0";
		read devpath1;
		RAIDDEVICEPATH=/dev/$devpath1;
		echo "RAID path is 1st: $RAIDPATH1 2nd: $RAIDPATH2, RAID name: $RAIDDEVICEPATH";
		echo -e "yes\n" | mdadm --create --verbose $RAIDDEVICEPATH --level=$RAIDLEVEL --raid-device=2 $RAIDPATH1 $RAIDPATH2;
	elif [ "$RAIDLEVEL" = "5" ]
	then
		echo "Enter 3rd device path for RAID: ex) sdc";
		read raiddevpath3;
		RAIDPATH3=/dev/$raiddevpath3;
		echo "Enter RAID Device name: ex) md0";
		read devpath1;
		RAIDDEVICEPATH=/dev/$devpath1;
		echo "RAID path is 1st: $RAIDPATH1 2nd: $RAIDPATH2, 3rd: $RAIDPATH3, RAID name: $RAIDDEVICEPATH";
	echo -e "yes\n" | mdadm --create --verbose $RAIDDEVICEPATH --level=$RAIDLEVEL --raid-device=3 $RAIDPATH1 $RAIDPATH2 $RAIDPATH3;
	else
		echo "Unrecognized value."
	exit 1
	fi
	Special_Test=1;
}

# RAID Check
RAID_Device_Check() 
{
	if [ "$RAIDLEVEL" = "0" ]
	then
		raidready=25;
	elif [ "$RAIDLEVEL" = "1" ] || [ "$RAIDLEVEL" = "5" ]
	then
		raidready=26;
	else
		echo "Unrecognized value."
	exit 1
	fi

	while [ : ]
	do
		mdadm --detail $RAIDDEVICEPATH | grep "State :" > raid_check;
		stat -c %s raid_check > filesize;
		filesizecheck=$(cat ./filesize | awk '{print $0}')
		declare -i filesizenum;
		filesizenum=$filesizecheck;
		RAID_State=$(mdadm --detail $RAIDDEVICEPATH | grep "State :" | head -1 |  awk '{print $3}')
		sleep 1m;
		if [ "$filesizenum" = "$raidready" ] && ( [ "$RAID_State" = "clean" ] || [ "$RAID_State" = "active" ] )
		then
			echo "RAID is ready"
		break;
		else
			echo "RAID is not ready"	
		fi
	done;
}

# Test for Precondition
Precondition_Test_Interface()
{
	Special_Test=0;
	echo "$Dash_Line";
	echo "Please Select the Interface";
	echo "$Dash_Line";
	select interface in "SATA" "SAS Single Port" "PCIe Single Port";
	do
	if [ "$interface" = "SATA" ]
	then
		Device_Select_Single_Port;
		Device_Information;
		System_Config;
		Random_Precondition SATA Single;
		Sequential_Read SATA Single 0;
		Sequential_Read_Consistency SATA Single 0;
		Sequential_Write SATA Single 100;
		Sequential_Write_Consistency SATA Single 100;
		Sequential_Precondition SATA Single;
		Random_Read SATA Single 0;
		Random_Read_Consistency SATA Single 0;
		Random_Mixed SATA Single 30;
		Random_Mixed SATA Single 50;
		Random_Mixed SATA Single 70;
		Random_Write SATA Single 100;
		Random_Write_Consistency SATA Single 100;
		Execution_Time_Check;
	exit 0
	elif [ "$interface" = "SAS Single Port" ]
	then
		Device_Select_Single_Port;
		Device_Information;
		System_Config;
		Random_Precondition SAS Single;
		Sequential_Read SAS Single 0;
		Sequential_Read_Consistency SAS Single 0;
		Sequential_Write SAS Single 100;
		Sequential_Write_Consistency SAS Single 100;
		Sequential_Precondition SAS Single;
		Random_Read SAS Single 0;
		Random_Read_Consistency SAS Single 0;
		Random_Mixed SAS Single 30;
		Random_Mixed SAS Single 50;
		Random_Mixed SAS Single 70;
		Random_Write SAS Single 100;
		Random_Write_Consistency SAS Single 100;
		Execution_Time_Check;
	exit 0
	elif [ "$interface" = "PCIe Single Port" ]
	then
		Device_Select_Single_Port;
		Device_Information;
		System_Config;
		Random_Precondition PCIe Single;
		Sequential_Read PCIe Single 0;
		Sequential_Read_Consistency PCIe Single 0;
		Sequential_Write PCIe Single 100;
		Sequential_Write_Consistency PCIe Single 100;
		Sequential_Precondition PCIe Single;
		Random_Read PCIe Single 0;
		Random_Read_Consistency PCIe Single 0;
		Random_Mixed PCIe Single 30;
		Random_Mixed PCIe Single 50;
		Random_Mixed PCIe Single 70;
		Random_Write PCIe Single 100;
		Random_Write_Consistency PCIe Single 100;
		Execution_Time_Check;
	exit 0
	break;
	else
	exit 1
	fi
	done
}

# Test Procedure
Test_Procedure()
{
	Interface=$1;
	Port=$2;
	Device_Select_${Port}_Port;
	Link_Speed_Check ${Interface};
	Device_Information;
	System_Config;
	Sequential_Precondition ${Interface} ${Port};
	Sequential_Read ${Interface} ${Port} 0;
	Sequential_Read_Consistency ${Interface} ${Port} 0;
	Sequential_Write ${Interface} ${Port} 100;
	Sequential_Write_Consistency ${Interface} ${Port} 100;
	Random_Precondition ${Interface} ${Port};
	Random_Read ${Interface} ${Port} 0;
	Random_Read_Consistency ${Interface} ${Port} 0;
	if [ "$Spec_Test" = "0" ]
	then
		Random_Mixed ${Interface} ${Port} 30;
		Random_Mixed ${Interface} ${Port} 50;
		Random_Mixed ${Interface} ${Port} 70;
	elif [ "$Spec_Test" = "1" ]
	then
		echo "Random_Mixed Test is skipped"
	else
		echo "Unrecognized value."
	exit 1
	fi
	Random_Write ${Interface} ${Port} 100;
	Random_Write_Consistency ${Interface} ${Port} 100;
	Execution_Time_Check;
}

Test_Procedure_DP_SP()
{
	Interface=$1;
	Device_Select_Dual_Port;
	Device_Information;
	System_Config;
	Sequential_Precondition ${Interface} Dual;
	Sequential_Read ${Interface} Dual 0;
	Sequential_Read_Consistency ${Interface} Dual 0;
	Sequential_Write ${Interface} Dual 100;
	Sequential_Write_Consistency ${Interface} Dual 100;
	Random_Precondition ${Interface} Dual;
	Random_Read ${Interface} Dual 0;
	Random_Read_Consistency ${Interface} Dual 0;
	if [ "$Spec_Test" = "0" ]
	then
	Random_Mixed ${Interface} Dual 30;
	Random_Mixed ${Interface} Dual 50;
	Random_Mixed ${Interface} Dual 70;
	elif [ "$Spec_Test" = "1" ]
	then
		echo "Random_Mixed Test is skipped"
	else
		echo "Unrecognized value."
	exit 1
	fi
	Random_Write ${Interface} Dual 100;
	Random_Write_Consistency ${Interface} Dual 100;
	Random_Read ${Interface} Single 0;
	Random_Read_Consistency ${Interface} Single 0;
	if [ "$Spec_Test" = "0" ]
	then
	Random_Mixed ${Interface} Single 30;
	Random_Mixed ${Interface} Single 50;
	Random_Mixed ${Interface} Single 70;
	elif [ "$Spec_Test" = "1" ]
	then
		echo "Random_Mixed Test is skipped"
	else
		echo "Unrecognized value."
	exit 1
	fi
	Random_Write ${Interface} Single 100;
	Random_Write_Consistency ${Interface} Single 100;
	Sequential_Precondition ${Interface} Single;
	Sequential_Read ${Interface} Single 0;
	Sequential_Read_Consistency ${Interface} Single 0;
	Sequential_Write ${Interface} Single 100;
	Sequential_Write_Consistency ${Interface} Single 100;
	Execution_Time_Check;
}

# Function Call
Block_Align_Select;
Test_Level_Select;

echo "$Dash_Line";
echo "Please Select the Test";
echo "$Dash_Line";
if [ "$Customized_Test" = "0" ]
then
	select interface in "SATA" "SAS Single Port" "SAS Dual Port" "SAS DP_SP" "PCIe Single Port" "PCIe Dual Port" "PCIe DP_SP" "RAID" "Precondition" 
	do
	if [ "$interface" = "SATA" ]
	then
		Test_Procedure SATA Single;
	exit 0
	elif [ "$interface" = "SAS Single Port" ]
	then
		Test_Procedure SAS Single;
	exit 0
	elif [ "$interface" = "SAS Dual Port" ]
	then
		Test_Procedure SAS Dual;
	exit 0
	elif [ "$interface" = "SAS DP_SP" ]
	then
		Test_Procedure_DP_SP SAS;
	exit 0
	elif [ "$interface" = "PCIe Single Port" ]
	then
		Test_Procedure PCIe Single;
	exit 0
	elif [ "$interface" = "PCIe Dual Port" ]
	then
		Test_Procedure PCIe Dual;
	exit 0
	elif [ "$interface" = "PCIe DP_SP" ]
	then
		Test_Procedure_DP_SP PCIe;
	exit 0
	elif [ "$interface" = "RAID" ]
	then
		RAID_Select;
	exit 0
	elif [ "$interface" = "Precondition" ]
	then
		Precondition_Test_Interface;
	exit 0
	else
		echo "Unrecognized value."
	exit 1
	fi
	done
elif [ "$Customized_Test" = "1" ]
then
	select interface in "Customized Single Port" "Customized Dual Port";
	do
	if [ "$interface" = "Customized Single Port" ]
	then
		Test_Procedure Customized Single;
	exit 0
	elif [ "$interface" = "Customized Dual Port" ]
	then
		Test_Procedure Customized Dual;
	exit 0
	else
		echo "Unrecognized value."
	exit 1
	fi
	done
fi

