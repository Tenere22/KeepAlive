#!/bin/bash
# GNU bash, version 5.1.8(1)-release (x86_64-pc-linux-gnu)
***********************************************************************###
# Home automation script to keep alive the internet connectivity 
# 
# 3 automated actions to be taken if a test fails.
# scenario: WLAN0 connected INTERNET / WLAN1 hotspot managed NetworkManager
#
# This is free software; you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.
#*******  V1.0.1 by Tenere22 ******************************************###
#
export TERM=xterm-256color
internet='8.8.8.8'      # IP google DNS for internet test
gateway='192.168.0.1'   # IP Router
repeater='10.42.0.17'   # IP Wifi Repeter / Router
ntime=20                # Slleeping time between a success ping to internet
c=2                     # Quantity of ping packets min.2 recommended
RED='\033[1;31m'        # Red Color
NC='\033[0m'            # No Color
GREEN='\033[1;32m'      # Green Color

ping1() {       test1=0 #Function to ping internet
            while [[ $test1 == 0 ]]; do
                printf "[+] ping Internet -> $internet     "
                ping -c$c $internet 1> /dev/null 2>&1
                test1=$?
                result
                test1b=0
                arp | grep 'wlan1' | cut -d ' ' -f1 |  while read output
                        do
                            printf "[+] ping WLAN1 IPs -> $output  ";
                            ping -c 1 "$output" > /dev/null
                            test1b=$?
                            result
                            sleep 1
                        done
                test1c=0
                printf "[+] ping gateway  -> $gateway ";
                ping -c$c $gateway 1> /dev/null 2>&1;
                test1c=$?
                result
                if [ $test1 != 0 ] || [ $test1b != 0 ] || [ $test1c != 0 ]; then
                    break
                else
                    sleep $ntime
                fi
            done
}
ping2() {       test1=0 #Function to ping internet
            while [[ $test1 == 0 ]]; do
                printf "[*] ping Internet -> $internet     "
                ping -c$c $internet 1> /dev/null 2>&1
                test1=$?
                    result
                test1b=0
                printf "[*] ping Repeater -> $repeater  ";
                ping -c$c $repeater 1> /dev/null 2>&1;
                test1b=$?
                    result
                test1c=0
                printf "[*] ping Gateway  -> $gateway ";
                ping -c$c $gateway 1> /dev/null 2>&1;
                test1c=$?
                    result
                if [ $test1 = 0 ] || [ $test1b = 0 ] || [ $test1c = 0 ]; then
                    break
                else
                    sleep $ntime
                fi
            done
}
action1() {   test1=" " #ACTION RESTART NETWORKS#
            printf "\n[+] reloading daemon *********************";
            systemctl daemon-reload; test1=$?; result2; sleep 5
            printf "[+] restarting Networking ****************";
            systemctl restart networking; test1=$?; result2; sleep 10 
            printf "[+] restarting NetworkingManager *********";
            systemctl restart NetworkManager; test1=$?; result2  
            sleep 40 
}
action2() {  test1=" " #ACTION RESTART WLAN0         #1#
            printf "\n[+] restarting WLAN0  *********************";
            ifconfig wlan0 down; ifconfig wlan1 down
            ifconfig wlan0 up; ifconfig wlan1 up
            test1=$?
            result2
            sleep 40
}
action3() {  test1=" " #iACTION RESTART DHCPD      #0#
            printf "\n[+] restarting DHCPD **********************";
            rm /var/run/dhcpd.pid
            killall -9  /usr/sbin/dhcpd
            systemctl restart isc-dhcp-server
            test1=$?
            result2
            sleep 30
}
action4() {  test1=" " #ACTION RESTART SERVER        #4#
            printf "\n[+] restarting SERVER in 20 seconds <ctrl+C> to STOP ***";
            sleep 20; nit 6
            test1=$?
            result2
}
result() {  printf "  [+] Result: " 
            if [[ $test1 == 0 ]]; then printf "${GREEN}[   OK   ]${NC} $(date)\r" 
            else printf "${RED}[ FAILED ]${NC} $(date)\n"
            fi
}
result2() {  printf "  [+] Result: " 
            if [[ $test2 == 0 ]]; then printf "${GREEN}[   OK   ]${NC} $(date)\n\n" 
            else printf "${RED}[ FAILED ]${NC} $(date)\n\n"
            fi
}

clear
while : ; do
    while : ; do 
        ping1           # TEST PING IPS
        action1         # RESTART NETWORKS 
        ping2
        if [ $test1 = 0 ] || [ $test1b = 0 ] || [ $test1c = 0 ]; then
            break
        fi
        action2          # RESTART WLAN0
        ping2
        if [ $test1 = 0 ] || [ $test1b = 0 ] || [ $test1c = 0 ]; then
            break
        fi
        action3           # RESTART DHCPD 
        ping2
        if [ $test1 = 0 ] || [ $test1b = 0 ] || [ $test1c = 0 ]; then
            break
            else action4  # ACTION RESTART SERVER :-(
        fi
        break
    done
done
