#!/bin/env zsh
#=================================================
# name:   weather.zsh
# author: Pawel Bogut <https://pbogut.me>
# date:   22/12/2020
#=================================================
cycle=0      #init cycle
tick=1       #tick every n secnds
refresh=600  #refresh every n seconds

metric=1 #Should be 0 or 1; 0 for F, 1 for C
location=""

icon_color=${1:--}

update_location() {
  location=$(curl -s 'http://ip-api.com/json' | jq -r '(.lat|tostring) + "," + (.lon|tostring)')
}

show_weather() {
  curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=${metric}&locCode=$location" |
      perl -ne '
        use utf8;
        if (/Currently/) {
          chomp;
          /\<title\>Currently: (.*)?\<\/title\>/;
          my @values=split(":",$1);

          if ($values[0] eq "Sunny" ||
            $values[0] eq "Mostly Sunny" ||
            $values[0] eq "Partly Sunny" ||
            $values[0] eq "Intermittent Clouds" ||
            $values[0] eq "Hazy Sunshine" ||
            $values[0] eq "Hazy Sunshine" ||
            $values[0] eq "Hot"
          ) {
            $color = "#fdc700";
            $icon = "";
          }

          if ($values[0] eq "Mostly Cloudy" ||
              $values[0] eq "Cloudy" ||
              $values[0] eq "Dreary (Overcast)" ||
              $values[0] eq "Fog"
          ) {
            $color = "#0069a8";
            $icon = "";
          }

          if ($values[0] eq "Showers" ||
              $values[0] eq "Mostly Cloudy w/ Showers" ||
              $values[0] eq "Partly Sunny w/ Showers" ||
              $values[0] eq "T-Storms" ||
              $values[0] eq "Mostly Cloudy w/ T-Storms" ||
              $values[0] eq "Partly Sunny w/ T-Storms" ||
              $values[0] eq "Rain"
          ) {
            # $icon = "";
            $icon = "";
            $color = "#0069a8";
          }

          if($values[0] eq "Windy") {
            $icon = "";
            $color = "#62748e";
          }

          if($values[0] eq "Flurries" ||
             $values[0] eq "Mostly Cloudy w/ Flurries" ||
             $values[0] eq "Partly Sunny w/ Flurries" ||
             $values[0] eq "Snow" ||
             $values[0] eq "Mostly Cloudy w/ Snow" ||
             $values[0] eq "Ice" || $values[0] eq "Sleet" ||
             $values[0] eq "Freezing Rain" ||
             $values[0] eq "Rain and Snow" ||
             $values[0] eq "Cold"
          ) {
            $color = "#cad5e2";
            $icon = "";
          }

          if($values[0] eq "Clear" ||
             $values[0] eq "Mostly Clear" ||
             $values[0] eq "Partly Cloudy" ||
             $values[0] eq "Intermittent Clouds" ||
             $values[0] eq "Hazy Moonlight" ||
             $values[0] eq "Mostly Cloudy" ||
             $values[0] eq "Partly Cloudy w/ Showers" ||
             $values[0] eq "Mostly Cloudy w/ Showers" ||
             $values[0] eq "Partly Cloudy w/ T-Storms" ||
             $values[0] eq "Mostly Cloudy w/ Flurries" ||
             $values[0] eq "Mostly Cloudy w/ Snow"
          ) {
            $icon = "";
            $color = "#2f0d68";
          }

          binmode(STDOUT, ":utf8");
          $label = $values[1] =~ s/C//r;
          if ($icon && $label) {
            print "{";
            print "\"icon_text\": \"$icon\",";
            # print $icon;
            print "\"icon_color\": \"$color\",";
            print "\"label\": \"$label\"";
            # print "</span>";
            # print "</big>";
            # $icon  = "";
            print "}";
          }
          # print $values[1] =~ s/C/糖/r;
        }'
  echo '' # new line for new i3blocks compatibility
}

refresh_with_location() {
  update_location
  show_weather
# echo '%{F#055}Colored%{F-}'
}

trap "refresh_with_location" USR1

update_location
show_weather

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    show_weather
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${tick}s
  wait
done
