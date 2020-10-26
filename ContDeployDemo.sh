#!/bin/bash
##
##  John D. Allen
##  Sr. Solutions Engineer
##  A10 Networks, Inc.
##  September, 2020
##
##  Licensed under Apache-2.0 for private use.
##  All other Rights Reserved.
##

DOCKERIP="192.168.99.99"
LASTCMT=""
BROWSER_START=false

function startWebBrowsers() {
  if ! $BROWSER_START ; then
    # Start up needed Web Browers...
    echo "Starting Web Browser Sessions..."
    # Demo Architecture
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --allow-file-access-from-files file://$(pwd)/arch.html &
    sleep 10
    # Portainer
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome http://$DOCKERIP:9000/ &
    # Nginx via Thunder Container
    while true; do
      # Wait for Thunder Container to start SLB...
      if curl -m2 http://$DOCKERIP:8080/ 2>&1 | grep "DOCTYPE html" > /dev/null; then
        /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome  http://$DOCKERIP:8080/index.html &
        break
      fi
    done
    BROWSER_START=true
  fi
}

function watch4Changes() {
  while true
  do 
    git fetch origin
    THISCMT=$(git log --oneline origin/master | head -n 1 | cut -f 1 -d ' ')
    if [ "$THISCMT" != "$LASTCMT" ]; then
      echo "Change Detected! Re-Applying Infrastructure..."
      git fetch
      git reset --hard origin/master
      #
      #  Test Terraform files, and if OK, Deploy...
      terraform plan
      if [ $? -eq 1 ]; then
        echo "ERROR! Terraform file(s) had errors. Aborting Deploy..."
        LASTCMT=$THISCMT
      else
        sleep 3
        terraform apply --auto-approve
        LASTCMT=$THISCMT
        echo "Containers Started."
        startWebBrowsers
      fi
    fi
    sleep 3
  done
}

##------------------------------------------------------------------------------------------------
##  MAIN
##------------------------------------------------------------------------------------------------
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
    
    watch4Changes
        
    break
  fi
  sleep 3
  echo -n "."
done


