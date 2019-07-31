#!/usr/bin/env bash
#
#
# author: albedo
# email: albedo@foxmail.com
# date: 20190726
# usage: install guestos
#

function menu() {
cat <<-EOF
++++++++++++++++++++++++++++++++++++
+                                  +
+             Virt-Manager         +
+                                  +
+----------------------------------+
+             1,view host          +
+----------------------------------+
+             2,new host           +
+----------------------------------+
+             3,remove host        +
+----------------------------------+
+             4,batch install      +
+----------------------------------+
+             5,quit               +
+----------------------------------+
EOF
}
function view(){
virsh list --all
}
function remo() { 
guests=`view | awk '{if($2 != "Name"){print $2}}'`
read -p "which do you want to delete" chooice
count=0
for i in $guests
do
	if [ "$i"  =  "$chooice" ];then
		virsh destroy $chooice &>>/dev/null
		snaps=`virsh snapshot-list $chooice | awk  'NR!=1{print $1}'`
		for a in $snaps
		do
			if [ "$a" != ""  ];then
				virsh snapshot-delete $chooice --snapshot-name $a
			fi	
		done
		virsh undefine $chooice
		rm -rf /var/lib/libvirt/images/$chooice.qcow2
		let count=1		
	fi
done
if [ $count -eq 0 ];then
	echo "a wrong hostname"
else
	echo "delete sucessfully"
fi
}
function new() {
#read -p "please input your guest name,(default a rand number) " gntemp
if [ "$3" = "" ];then
	num=`openssl rand -hex 2`
	gn=vm$num
else
	gn=$3
fi 
uu=`uuidgen`
diskdir="/var/lib/libvirt/images/$gn.qcow2"
#sl1=0x`openssl rand -hex 1`
macaddr=52:54:00:`openssl rand -hex 3| sed -nr 's/(..)(..)(..)/\1:\2:\3/p'`
#sl2=0x`openssl rand -hex 1`
if [ "$4" = "" ];then
	mem=10240000
else
	mp=$4
	memtp=$(echo "scale=4;$mp * 1000000"|bc)
	mem=${mp%.*}
fi
#read -p "please input your cpu cores (default 1) " cpucore
if [ "$5" = "" ];then
	cpus=1
else
	cpus=$5
fi
xmldir="/etc/libvirt/qemu/$gn.xml"
cp $1 $xmldir
sed -ie "9 s/\(<.*>\).*\(<\/.*>\)/\1$gn\2/;10 s/\(<.*>\).*\(<\/.*>\)/\1$uu\2/;11,12 s/\(<.*>\).*\(<\/.*>\)/\1$mem\2/;13 s/\(<.*>\).*\(<\/.*>\)/\1$cpus\2/" $xmldir
sed -ie "41 s!\(file=\'\).*\'!\1$diskdir\'!;74 s/\(address=\'\).*\'/\1$macaddr\'/" $xmldir
#43 s/\(slot=\'\).*\'/\1${sl1}\'/;74 s/\(address=\'\).*\'/\1$macaddr\'/;
#77 s/\(slot=\'\).*\'/\1${sl2}\'/" $xmldir 
cp $2 $diskdir
virsh define $xmldir
}
function batc(){
if [ ! -f /usr/bin/expect ];then
	yum -y install expect &>/dev/null
fi
read -p "please input how much host you want to create " m
while (("$m > 0")) 
do
new $basexml $baseimg
let m--
done
}

#####main
baseimg="/var/lib/libvirt/images/temp.qcow2"
basexml="/etc/libvirt/qemu/temp.xml"
menu
read -p "please input your choose" n
case $n in 
1)
	view
	;;
2)
	read -p "please input your guest name,(default a rand number) " gntemp
	read -p "please input your memory /G (default 1G) " memtemp
	read -p "please input your cpu cores (default 1) " cpucore
	new $basexml $baseimg $gntemp $memtemp $cpucore
	;;
3)
	remo
	;;
4)
	batc
	;;
5)
	exit
	;;
*)
	echo ""
esac
 
