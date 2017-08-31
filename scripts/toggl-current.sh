#!/bin/bash
#=================================================
# name:   toggl-current.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   29/08/2017
#=================================================
last_entry=$(curl -v -u 788bd91dea4187a817d63bc0a08994b0:api_token -X GET 'https://www.toggl.com/api/v8/time_entries' 2> /dev/null | jq '.[-1]')
if [[ $(echo $last_entry | jq '.duration') -lt 0 ]]; then
  echo $last_entry | jq -r '.description'
else
  echo 'No activity'
fi
