#!/bin/bash

#set -x
#sudo apt-get install -y tftp-hpa nfs-common stress-ng 

print_usage(){
  echo $"Usage: $0 {stressng|tftp|nfs|stressng|modprobe|\
ifconfig|lspci|lsblk|mkfs|compress|prompt|source|stressng|all}"
  exit 1
}

if [ $# -lt 1 ]; then
  print_usage
fi


run_modprobe(){
# load/unload ko

  sudo modprobe reiserfs
  if [ "`lsmod | grep reiser`" == "" ]; then
    echo "modprobe Failed"
  else
    echo "modprobe Passed"
  fi

}

run_ifconfig(){
# Confirm that 'ifconfig -a' shows the right devices and has an IP
#interface_name="enP7p1s0"
#interface_name="eth"

  interface_name="HWaddr"
  if [ "`ifconfig -a | grep ${interface_name} | wc -l`" -lt "3" ]; then
    echo "ifconfig Failed"
  else
   echo "ifconfig Passed"
  fi

  if [ "`ifconfig -a | grep 228 | grep inet`" == "" ]; then
    echo "ip Failed"
  else
    echo "IP test Passed"
  fi
}

run_lspci(){
# Confirm lspci displays the PCI devices attached
# This varies because all of the systems do not have mellanox cards as of 02/17/2016

  lspci_name="Intel"
  #lspci_name="Mellanox"
  if [ "`lspci | grep ${lspci_name}`" == "" ]; then
    echo "lspci Failed"
  else
    echo "lscpi Passed"
  fi
}

run_lsblk(){
# Confirm lsblk displays the media devices that are available

  if [ "`lsblk | grep sda`" == "" ]; then
    echo "lsblk Failed"
  else
    echo "lsblk Passed"
  fi
}

run_mkfs_and_dd(){
# mkfs and dd test
  dd if=/dev/zero of=disk.img bs=1M count=50
  if [ $? -ne 0 ]; then
    echo "dd Failed"
  else
    echo "dd Passed"
  fi

  mkfs.ext3 disk.img
  if [ $? -ne 0 ]; then
    echo "mkfs Failed"
  else
   echo "mkfs Passed"
  fi
 rm disk.img

}

run_tar_and_gzip(){
# Create and extract something using tar and gzip
  dd if=/dev/urandom of=test.bin bs=1024 count=16
  ORIG_MD5SUM=`md5sum test.bin | cut -d \  -f 1`
  tar zcvf test.bin.tgz test.bin
  rm -f test.bin

  if [ x$ORIG_MD5SUM == x`md5sum test.bin.tgz | cut -d \  -f 1` ]; then
    echo "Compression Failed"
  else
    echo "Compression Passed"
  fi

  tar zxvf test.bin.tgz
  rm -f test.bin.tgz

  if [ x$ORIG_MD5SUM != x`md5sum test.bin | cut -d \  -f 1` ]; then
    echo "File difference after decompress -  Failed"
  else
    echo "No File difference after decompression Passed"
  fi

rm -f test.bin
}

run_update_prompt(){
# Update the PS1 prompt

  export PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\wTEST\$"

  if [ "`echo $PS1 | grep TEST`" == "" ]; then
    echo "PS1 Failed"
  else
    echo "PS1 prompt changed Passed"
  fi

}

run_source_cmd(){
# Source a bash file and run a command from it

  echo "#!/bin/bash\ncat /proc/version\n" > test.sh
  source test.sh

  if [ $? -eq 0 ]; then
    echo "Source Passed"
  else
    echo "Source Failed"
  fi

  rm -f test.sh
}

# stress-ng
run_stress_ng(){
#stress-ng -a 10 -t 300

stress-ng --cpu 4 --vm 2 --hdd 1 --fork 8 --switch 4 --timeout 5m --metrics-brief

  if [ "`cat /proc/cpuinfo | grep processor | wc -l`" -gt "26" ]; then
    echo "stress-ng Passed"
  else
    echo "Stress-ng Failed"
  fi

} # end run_stress_ng


run_all_tests(){
  #run_rsync
  #run_tftp
  #run_nfs
  run_modprobe
  run_ifconfig
  run_lspci
  run_lsblk
  run_mkfs_and_dd
  run_tar_and_gzip
  run_update_prompt
  run_source_cmd
  run_stress_ng
}


print_results(){
echo "********************************"
echo "Summary"
echo "********************************"
echo ""
echo "Passed"
echo "--------"
grep -i Passed output.txt
total_passed=`grep -i passed output.txt | wc -l`
echo ""
echo ""
echo "Failures"
echo "--------"
grep -i Failed output.txt
total_failed=`grep -i Failed output.txt | wc -l`
echo "********************************"
echo "Passed = $total_passed     Failed = $total_failed"
echo "********************************"
rm output.txt
}

for testcase in $@ ; 
do
  case "$testcase" in
       	  rsync)
     	      #run_rsync | tee -a output.txt
	     ;;      
          tftp)
              #run_tftp | tee -a output.txt
              ;; 
	  nfs)
	     #run_nfs | tee -a output.txt
	     ;;
	  modprobe)
	     run_modprobe | tee -a output.txt
	     ;;
  	  ifconfig)
	     run_ifconfig | tee -a output.txt
	     ;;
	  lspci)
	     run_lspci | tee -a output.txt
	     ;;
	  lsblk)
	     run_lsblk | tee -a output.txt
	     ;;
          mkfs|dd)
	     run_mkfs_and_dd | tee -a output.txt
	     ;;
	  compress)
	     run_tar_and_gzip | tee -a output.txt
	     ;;
	  prompt)
	     run_update_prompt  | tee -a output.txt 
	     ;;
	  source)
	     run_source_cmd | tee -a output.txt
	     ;;
          stressng)
             run_stress_ng | tee -a output.txt
            ;;
       	  all)
	     run_all_tests | tee -a output.txt
	     ;;
          *)
            print_usage
  esac
done


print_results


