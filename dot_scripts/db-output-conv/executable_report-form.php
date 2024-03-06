#!/bin/php
<?php
if ($argc == 3) {
    $inputFile = $argv[1];
    $outputFile = $argv[2];
}
if ($argc == 2) {
    $inputFile = 'php://stdin';
    $outputFile = $argv[1];
}
if ($argc == 1) {
    $inputFile = 'php://stdin';
    $outputFile = 'php://stdout';
}

$fin = fopen($inputFile, 'r');
$fout = fopen($outputFile, 'w');

$yad = 'yad --date-format "%Y-%m-%d" --form ';

$placeholders = [];
$params = [];

$yadRun = false;

$content = "";

while(!feof($fin)) {
    $line = fgets($fin);
    if ($line != $title = preg_replace('/^-- title:(.*)$/', '$1', $line)) {
        $yad .= ' --title=' . trim($title);
        continue;
    }
    if ($line != $field = preg_replace('/^-- field:(.*)$/', '$1', $line)) {
        $tag = preg_replace('/(^[A-Za-z0-9_]*).*/', '$1', trim($field));
        $placeholders[$tag] = ' --field=' . trim(str_replace('_', '__', $field));
        continue;
    }
    preg_match_all('/\:([A-Za-z][A-Za-z0-9_]+)/', $line, $matches);
    if (!empty($matches)) {
        foreach ($matches[1] as $tag) {
            if (!isset($placeholders[$tag])) {
                $placeholders[$tag] = ' --field=' . trim(str_replace('_', '__', $tag));
            }
        }
    }
    $content .= $line;
}

if (empty($placeholders)) {
    fclose($fin);
    fclose($fout);
    echo $content;
    exit(0);
}

$yad .= implode(' ', $placeholders);
$result = shell_exec($yad);
if (!$result) {
    exit(15);
}

$tags = array_map(function($key) {
    return ":$key";
}, array_keys($placeholders));

$values = explode('|', trim($result));
array_pop($values);

foreach ($values as $val) {
    if (!$val) {
        exit(10);
    }
}

$first = true;
foreach (explode("\n", $content) as $line) {
    if ($first) {
        $first = false;
    } else {
        fputs($fout, "\n");
    }
    if (preg_match('/^--/', $line)) {
        fputs($fout, $line);
    } else {
        fputs($fout, str_replace($tags, $values, $line));
    }
}

fclose($fin);
fclose($fout);
