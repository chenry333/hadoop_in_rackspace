#!/bin/bash

# This file is generated by a python script which polls the rackspace API
# Setup our variables
IPT=/sbin/iptables
EXT=eth0
INT=eth1
#Flush any existing rules and set default accept just in case
$IPT -P INPUT ACCEPT
$IPT -F
#Setup Global iptables rules
#Loopback is important :)
$IPT -A INPUT -i lo -j ACCEPT
#lets allow established/related connections
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#lets allow SSH connections - but rate limit
$IPT -I INPUT -p tcp --dport 22 -i $EXT -m state --state NEW -m recent --set
$IPT -I INPUT -p tcp --dport 22 -i $EXT -m state --state NEW -m recent --update --seconds 60 --hitcount 3 -j DROP
if [ $HOSTNAME == puppetmaster.example.com ]; then 
$IPT -A INPUT -p tcp --syn --dport 22 -j ACCEPT
fi
$IPT -A INPUT -p tcp --syn --dport 80 -j ACCEPT
#Lets drop bad stuff
$IPT -P INPUT DROP



## adding rules for puppetmaster.example.com
$IPT -A INPUT -i $INT -s 10.179.169.251 -j ACCEPT

## adding rules for hadoop-template.example.com
$IPT -A INPUT -i $INT -s 10.179.169.53 -j ACCEPT

## adding rules for c1-m001.example.com
$IPT -A INPUT -i $INT -s 10.183.58.135 -j ACCEPT

## adding rules for c1-n001.example.com
$IPT -A INPUT -i $INT -s 10.183.58.136 -j ACCEPT

## adding rules for c1-n002.example.com
$IPT -A INPUT -i $INT -s 10.183.58.137 -j ACCEPT

## adding rules for c2-m001.example.com
$IPT -A INPUT -i $INT -s 10.183.58.167 -j ACCEPT

## adding rules for c2-n001.example.com
$IPT -A INPUT -i $INT -s 10.183.58.168 -j ACCEPT

## adding rules for c2-n002.example.com
$IPT -A INPUT -i $INT -s 10.183.58.170 -j ACCEPT
