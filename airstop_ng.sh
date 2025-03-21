#!/bin/bash

# airstop_ng by ef-code

echo "Easily exit monitor mode on a wireless interface."
echo

while true; do
  read -p "Enter the wireless interface name (e.g., wlan0): " interface
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
  else
      echo "Warning: Failed to stop monitor mode using airmon-ng. Proceeding with other commands."
  fi

  # Bring the interface down
  sudo ip link set "$interface" down
  if [ $? -ne 0 ]; then
        echo "Error: Failed to bring interface down."
        exit 1
  fi

  # Set the interface to managed mode
  sudo iwconfig "$interface" mode managed
  if [ $? -ne 0 ]; then
        echo "Error: Failed to set interface to managed mode."
        exit 1
  fi

  # Bring the interface back up
  sudo ip link set "$interface" up
  if [ $? -ne 0 ]; then
        echo "Error: Failed to bring interface up."
        exit 1
  fi

  # Restart NetworkManager
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