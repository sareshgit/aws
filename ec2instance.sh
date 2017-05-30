#!/bin/bash
clear
aws configure
echo
echo
echo 				"Welcome! This script will Launch a Ec2  instance"
echo
echo "Please enter the name of security group: "
# Ask the user for aws security group name to be
read g_name

g_id=`aws ec2 create-security-group --group-name $g_name --description "security group for $g_name development environment in EC2" | grep sg | cut -d '"' -f4`
echo
echo
echo  "The security group has been created.  "
echo
echo

echo "group id is $g_id"

# Command to add open  ports in Above created security group

#enable ssh
aws ec2 authorize-security-group-ingress --group-name $g_name --protocol tcp --port 22 --cidr 0.0.0.0/0
#enable HTTP

aws ec2 authorize-security-group-ingress --group-name $g_name --protocol tcp --port 80 --cidr 0.0.0.0/0
#enable HTTPS
aws ec2 authorize-security-group-ingress --group-name $g_name --protocol tcp --port 443 --cidr 0.0.0.0/0
echo -e "By Default, the following ports are enabled: \n 22		SSH\n 80		HTTP\n 443 		HTTPS"

###
### Create pem file
####
clear

echo " The  key pair "
echo -e "\n\n\n"

# shit goes here
read -p "Do you want to create a new pem file " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Please enter the name of key-pair to be created:"
  read kp
  aws ec2 create-key-pair --key-name $kp --query 'KeyMaterial' --output text > $kp.pem
  echo -e "\n\n\n"
  echo "Key-pair Created SuccessFully.\n  "
  chmod 400 $kp.pem
  mv $kp.pem ~/
else
	echo "enter name of pem file | Just name - don't include .pem extension"
	read kp
	echo $kp.pem
fi

# finally Launch instance with ubuntu

echo -e " \n\n\n\ "
echo "Please enter the type of instance (Example format : t2.small)" :
read i_type
echo "Enter the ami of Operating system you want to lauch"
read ami

# Launch ec2 with exiting sec grp and key pair
dev=`aws ec2 run-instances --image-id $ami --security-group-ids $g_id --count 1 --instance-type $i_type --key-name $kp --query 'Instances[0].InstanceId' --block-device-mappings  '{"DeviceName": "/dev/sda1","Ebs": {"VolumeSize": 30}}' | cut -d '"' -f2`

#--user-data file:///Users/spidy/shell-scripts/non-interactive-apache2.sh

#Create Name tag
aws ec2 create-tags --resources $dev --tags Key=Name,Value=ec2-dev


echo "instance created."

#Assign  new Elastic Ip address
eip_dev=`aws ec2 allocate-address |grep Public | cut -d '"' -f4`

echo "Elastic ip allocated. :)"

echo "Waiting 60 seconds ..."

for ((i=60;i>=1;i--))
do
	echo -e "							$i \n"
	sleep 1
done

# Assign Elatic ip to dev server
aws ec2 associate-address --instance-id $dev --public-ip $eip_dev

# Print details

echo "Instance id is : $dev   and Elastic-IP is : $eip_dev "
