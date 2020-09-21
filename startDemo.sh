#!/bin/bash
##
##  StartDemo.sh
##
##  NOTE:  This only works on Mac OSX!!
##
##  John D. Allen
##  August, 2020
##

DOCKERIP="192.168.99.99"

echo -n "Checking to see if Docker VM is running..."
if  ! VBoxManage showvminfo "Docker Server" --machinereadable | egrep '^VMState="running"' > /dev/null; then
  echo "No. Starting Docker VM..."
  # Startup VM first
  VBoxManage startvm --type headless "Docker Server"
  sleep 10
else
  echo "Running."
fi

#  Start up Containers for Demo
echo -n "Checking to see if Docker is Ready for commands..."
while true; do
  # Check to make sure Docker is ready for commands...
  if curl -m 2 http://$DOCKERIP:2375/ 2>&1 | grep "message" > /dev/null; then
    echo "Yes"
    terraform apply --auto-approve
    break
  fi
  sleep 3
  echo -n "."
done
echo "Containers Started."

# Start up needed Web Browers...
# Portainer
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --new-window http://$DOCKERIP:9000/ &
# Nginx via Thunder Container
while true; do
  # Wait for Thunder Container to start SLB...
  if curl -m2 http://$DOCKERIP:8080/ 2>&1 | grep "DOCTYPE html" > /dev/null; then
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome  http://$DOCKERIP:8080/index.html &
    break
  fi 
done

echo "Startup Finished."

