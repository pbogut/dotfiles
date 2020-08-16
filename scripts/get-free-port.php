#!/bin/php
<?php

$first_port = 7000;
if ($argc > 1) {
    $first_port = $argv[1];
}


$used_ports = `netstat -tuplen 2>/dev/null | grep 127.0.0.1 | awk '{print $4}' | sed 's/.*://g' | sort -n`;
$used_ports = explode("\n", $used_ports);


$port = (int) $first_port;
while (in_array($port, $used_ports)) {
    $port++;
}

echo $port;
