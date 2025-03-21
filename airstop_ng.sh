#!/bin/bash

# Improved script for exiting monitor mode on a wireless interface

echo "Easily exit monitor mode on a wireless interface."
echo

# Input validation loop for interface name
while true; do
  read -p "Enter the wireless interface name (e.g., wlan0 or wlan0mon): " interface
  if [[ -n "$interface" ]]; then
    break
  else
    echo "Interface name cannot be empty. Please try again."
  fi
done

# Check if airmon-ng is installed
if ! command -v airmon-ng &> /dev/null; then
  echo "Error: airmon-ng is not installed. Please install the aircrack-ng suite."
  exit 1
fi

# Check if the interface exists
if ! ip link show "$interface" &> /dev/null; then
  echo "Error: Interface '$interface' does not exist."
  exit 1
fi

# Check if the interface is in monitor mode
if iwconfig "$interface" | grep -q "Mode:Monitor"; then

  echo "Stopping monitor mode on $interface..."

  # Stop monitor mode
  if sudo airmon-ng stop "$interface" &> /dev/null; then
      echo "Monitor mode stopped."
      sleep 1 # Add a 1-second delay
  else
      echo "Warning: Failed to stop monitor mode using airmon-ng. Proceeding with other commands."
  fi

  # Determine the original interface name (remove "mon" if present)
  original_interface="${interface%mon}"

  # Bring the monitor interface down. Only if the interface still exists.
  if ip link show "$interface" &> /dev/null; then
    sudo ip link set "$interface" down
    if [ $? -ne 0 ]; then
      echo "Error: Failed to bring interface down."
      exit 1
    fi
  else
    echo ""
  fi

  # Set the original interface to managed mode
  if [[ "$interface" != "$original_interface" ]]; then # only do this if the interface ends in mon.
    sudo iwconfig "$original_interface" mode managed
    if [ $? -ne 0 ]; then
          echo "Error: Failed to set original interface to managed mode."
          exit 1
    fi

    # Bring the original interface back up
    sudo ip link set "$original_interface" up
    if [ $? -ne 0 ]; then
          echo "Error: Failed to bring original interface up."
          exit 1
    fi
    interface="$original_interface" #set interface to the original interface for the following commands.
  else
    sudo iwconfig "$interface" mode managed
    if [ $? -ne 0 ]; then
          echo "Error: Failed to set interface to managed mode."
          exit 1
    fi
    sudo ip link set "$interface" up
    if [ $? -ne 0 ]; then
          echo "Error: Failed to bring interface up."
          exit 1
    fi
  fi

  # Restart NetworkManager (or wpa_supplicant if applicable)
  if command -v systemctl &> /dev/null; then
    sudo systemctl restart NetworkManager
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to restart NetworkManager. Network connectivity might be affected."
    fi
  else
    echo "Warning: systemctl not found. Manual restart of network services might be required."
  fi

  echo "Successfully exited monitor mode on interface $interface."
else
  echo "Interface $interface is not in monitor mode."
fi

exit 0