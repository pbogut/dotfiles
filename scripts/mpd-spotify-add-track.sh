#!/bin/bash
# mpc="mpc -p ${MOPIDY_PORT:-6600}"
mpc="mpc"
track=`$mpc current -f '%title% - %artist% - %album%'`
track_id=`$mpc current -f '%file%' | sed 's/.*:track:\(.*\)/\1/g'`
token=`cat ~/.spotify-api-token`
if [ -z $token ]; then
    echo "Token not found, you need to place token in ~/.spotify-api-token file"
    echo "You can get token by visiting https://developer.spotify.com/web-api/console/put-current-user-saved-tracks/"
    exit 1
fi
if [ "$track_id" == "" ]; then
    echo "Can't find the track:"
    echo -e "\t$track (id:$track_id)"
    exit 1
fi

echo "Adding track to library:"
echo -e "\t$track (id:$track_id)"
curl -s -X PUT "https://api.spotify.com/v1/me/tracks?ids=$track_id" -H "Accept: application/json" -H "Authorization: Bearer $token"
