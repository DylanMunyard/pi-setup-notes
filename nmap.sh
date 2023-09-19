# Parses output of nmap to find the Pis. 
# usage: ./nmap.sh nmap.txt where nmap.txt is the result of sudo nmap -sn 192.168.1.0/24 > nmap.txt
awk '/^Nmap scan report/ {printf "%s ", $5; getline; getline; print $5}' $1 | awk '/Pi$/ {print $1}'