#!/bin/bash


for i in `cat images`
do
#m=`echo $i | sed -r 's/\//\./g'`
docker load < $i
done

for i in `cat tag | awk '{print $1":"$2"@"$3}'`
do
id=`echo $i | awk -F@ '{print $2}' `
tag=`echo $i | awk -F@ '{print $1}'`
docker tag $id $tag
done

