#!/bin/bash
#=================================================
# name:   toggl-current.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   29/08/2017
#=================================================
_current_task() {
  token=$(config toggl/api_token)
  last_entry=$(curl -v -u $token:api_token -X GET 'https://www.toggl.com/api/v8/time_entries' 2> /dev/null | jq '.[-1]')

  if [[ $(echo $last_entry | jq '.duration') -lt 0 ]]; then
    description=$(echo $last_entry | jq '.description')
    echo '{"full_text": '$description'}'
  else
    echo '{"full_text": "No activity"}'
  fi
}

button=$1

if [[ "$button" == "1" ]]; then
  TogglDesktop
  _current_task
elif [[ "$button" == "2" ]]; then
  _current_task
elif [[ "$button" == "3" ]]; then
  _current_task
else
  _current_task
fi
