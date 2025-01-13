echo "Easily exit monitor mode on an interface"
echo
echo "Input interface name"
read interface

sudo airmon-ng stop $interface
sudo ifconfig $interface down
sudo iwconfig $interface mode managed
sudo systemctl restart NetworkManager

echo "Successfully exited monitor mode on interface $interface"
