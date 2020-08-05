#!/bin/bash
#AccuWeather (r) RSS weather tool for i3blocks

metric=1 #Should be 0 or 1; 0 for F, 1 for C
# location=$1

# if [ -z $1 ]; then
    location=$(curl -s 'http://ip-api.com/json' | jq -r '(.lat|tostring) + "," + (.lon|tostring)')
# fi

if [ "$1" != "" ]; then
    browser 'https://pogoda.interia.pl/prognoza-dlugoterminowa-opole,cId,24308'
fi

# echo $location
curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=${metric}&locCode=$location" |
    perl -ne 'use utf8; if (/Currently/) {chomp;/\<title\>Currently: (.*)?\<\/title\>/; my @values=split(":",$1); if( $values[0] eq "Sunny" || $values[0] eq "Mostly Sunny" || $values[0] eq "Partly Sunny" || $values[0] eq "Intermittent Clouds" || $values[0] eq "Hazy Sunshine" || $values[0] eq "Hazy Sunshine" || $values[0] eq "Hot")
{my $sun = "";binmode(STDOUT, ":utf8");print "$sun";}

if( $values[0] eq "Mostly Cloudy" || $values[0] eq "Cloudy" || $values[0] eq "Dreary (Overcast)" || $values[0] eq "Fog")
{my $cloud = "";binmode(STDOUT, ":utf8");print "$cloud";}

if( $values[0] eq "Showers" || $values[0] eq "Mostly Cloudy w/ Showers" || $values[0] eq "Partly Sunny w/ Showers" || $values[0] eq "T-Storms"|| $values[0] eq "Mostly Cloudy w/ T-Storms"|| $values[0] eq "Partly Sunny w/ T-Storms"|| $values[0] eq "Rain"){my $rain = "";binmode(STDOUT, ":utf8");print "$rain";}

if( $values[0] eq "Windy")
{my $wind = "";binmode(STDOUT, ":utf8");print "$wind";}

if($values[0] eq "Flurries" || $values[0] eq "Mostly Cloudy w/ Flurries" || $values[0] eq "Partly Sunny w/ Flurries"|| $values[0] eq "Snow"|| $values[0] eq "Mostly Cloudy w/ Snow"|| $values[0] eq "Ice"|| $values[0] eq "Sleet"|| $values[0] eq "Freezing Rain"|| $values[0] eq "Rain and Snow"|| $values[0] eq "Cold")
{my $snow = "";binmode(STDOUT, ":utf8");print "$snow";}

if($values[0] eq "Clear" || $values[0] eq "Mostly Clear" || $values[0] eq "Partly Cloudy"|| $values[0] eq "Intermittent Clouds"|| $values[0] eq "Hazy Moonlight"|| $values[0] eq "Mostly Cloudy"|| $values[0] eq "Partly Cloudy w/ Showers"|| $values[0] eq "Mostly Cloudy w/ Showers"|| $values[0] eq "Partly Cloudy w/ T-Storms"|| $values[0] eq "Mostly Cloudy w/ Flurries" || $values[0] eq "Mostly Cloudy w/ Snow")
{my $night = "";binmode(STDOUT, ":utf8");print "$night";}
print"$values[1]"; }'
echo '' # new line for new i3blocks compatibility
