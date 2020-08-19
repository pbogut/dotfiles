#!/bin/php
<?php
if ($argc < 2) {
    echo "\n";
    echo "\tUssage: conv.php {source_file} [output_file]\n";
    echo "\n";
    exit;
}

$inputFile = $argv[1];
$outputFile = isset($argv[2]) ? $argv[2] : 'php://stdout';

$fin = fopen($inputFile, 'r');
$fout = fopen($outputFile, 'w');

$source = null;

$firstLine = fgets($fin);
if (strlen($firstLine) &&
    $firstLine[0] == '+' &&
    strlen(str_replace(['+', '-'], '', $firstLine))
) {
    $source = 'mysql';
}

if (!$source) {
    echo "Source format not recognized :(\n";
    exit(1);
}

include("$source.php");
