#!/bin/bash
#
#
#


#for i in `cat tag`
#do
#m=`printf $i | sed -r 's/\//\./g'`
#docker save -o $m.tar $i
#done
for i in `cat tag | awk '{print $1":"$2"@"$3}'`
do
id=`echo $i | awk -F@ '{print $1}' `
tag=`echo $i | awk -F@ '{print $1}'| sed -r 's/\///g'`
#docker tag $id $tag
docker save -o ${tag}.tar $id
done


