#!/bin/bash

if [ -z $1 ] || [ -z $2 ] ; then
  echo "Usage: $0 <simulatorId> <bundleId>"
  exit 1
fi


for plistFile in `grep $2 ~/Library/Developer/CoreSimulator/Devices/${1}/data/Containers/Data/Application/*/.*.plist | awk '{ print $3 }'` ; do
   /usr/bin/plutil -convert xml1 -o - $plistFile | grep ">${2}<" > /dev/null
   if [ $? -eq 0 ] ; then
     echo $plistFile | sed 's#/[^/]*plist$##'
     exit 0
   fi
done

exit 1
