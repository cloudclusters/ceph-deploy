#!/bin/bash

remove_osd_id=`cat hosts|grep "remove_osd_id"|cut -d"=" -f2`

if ! ceph osd find ${remove_osd_id} &>/dev/null
then
    echo -e "\e[31mosd.${remove_osd_id} was not found !\e[0m"
    exit
else
    remove_node_name=`ceph osd find ${remove_osd_id}|grep host|awk -F":" '{print $2}'|awk -F '"' '{print $2}'`
fi

echo -e "Now I will remove osd \e[33m[osd.${remove_osd_id}]\e[0m"
read -p "Do you sure (yes/no):" yn
if [ "$yn" == "y" ] || [ "$yn" == "Y" ] || [ "$yn" == "YES" ] || [ "$yn" == "yes" ]
then
    sed -i "/\[remove_node\]/a\\${remove_node_name}" hosts
    ansible-playbook remove_osd.yaml
    sleep 1
    sed -ie '/remove_node/{n;d}' hosts
elif [ "$yn" == "n" ] || [ "$yn" == "N" ] || [ "$yn" == "no" ] || [ "$yn" == "NO" ]
then
    echo -e "\e[34mYou have canceled \e[0m"
else
    echo -e "\e[31mYour input is error\e[0m"
fi

