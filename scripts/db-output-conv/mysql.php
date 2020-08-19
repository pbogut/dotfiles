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

$firstLine = fgets($fin);

$colNum = strlen(trim(str_replace('-', '', $firstLine))) - 1;
$firstLine = substr($firstLine, 1);

$cols = [];


for($i = 0; $i < $colNum; $i++) {
    $size = strpos($firstLine, '+');
    $cols[] = $size;
    $firstLine = substr($firstLine, $size + 1);
}


while(!feof($fin)) {
    $line = fgets($fin);
    if (!trim(str_replace(['-', '+'], '', $line))) {
        continue;
    }
    $row = [];
    foreach ($cols as $size) {
        $row[] = trim(substr($line, 1, $size));
        $line = substr($line, $size + 1);
    }
    fputcsv($fout, $row);
}

fclose($fout);
fclose($fin);
