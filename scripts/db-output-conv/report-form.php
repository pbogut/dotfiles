#!/bin/php
<?php

if ($argc < 2) {
    echo "\n";
    echo "\tUssage: conv {source_file} [output_file]\n";
    echo "\n";
    exit;
}

$inputFile = $argv[1];
$outputFile = isset($argv[2]) ? $argv[2] : 'php://stdout';


$fin = fopen($inputFile, 'r');
$fout = fopen($outputFile, 'w');

$yad = 'yad --date-format "%Y-%m-%d" --form ';

$placeholders = [];
$params = [];

$yadRun = false;
while(!feof($fin)) {
    $line = fgets($fin);
    if ($line != $title = preg_replace('/^-- title:(.*)$/', '$1', $line)) {
        $yad .= ' --title=' . trim($title);
    }
    if ($line != $field = preg_replace('/^-- field:(.*)$/', '$1', $line)) {
        $yad .= ' --field=' . trim($field);
        $placeholders[] = preg_replace('/(^[A-Za-z0-1]*).*/', '$1', trim($field));
    }
    if (!preg_match('/^-- .*/', $line) && !$yadRun) {
        $yadRun = true;
        $result = shell_exec($yad);
        if (!$result) {
            exit(15);
        }
        $values = explode('|', trim($result));
        foreach ($placeholders as $idx => $placeholder) {
            $params[$placeholder] = $values[$idx];
        }
    }

    if (!preg_match('/^-- .*/', $line) && $yadRun) {
        foreach ($params as $param => $value) {
            $line = str_replace(":{$param}", $value, $line);
        }
    }

    fputs($fout, $line);
}



fclose($fin);
fclose($fout);
