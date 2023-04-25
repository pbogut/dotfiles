#!/usr/bin/env bash
tmp_file=$(mktemp)
cat /dev/stdin >"$tmp_file"
set -e
set -o pipefail

from=$(exail -f "$tmp_file" --from-email)
acc=${from##*@}

if [[ $1 == "--preview" ]]; then
  preview="$(mktemp -d)/email.html"
  enrichmail --html-preview "$tmp_file" >"$preview"
  browser "$preview" >/dev/null 2>&1
  # perevent mutt form sending email
  exit 1
fi

user=$(config "email/$from/user" "$from")
pass=$(config "email/$from/pass")
imap_url=$(config "email/$acc/imap/host")
imap_port=$(config "email/$acc/imap/port" 993)
tracking_base_url=$(config "email/open_tracking/api_url")

# shellcheck disable=2068
msmtp -a "$acc" \
  --passwordeval="config email/$from/pass" \
  --user="$user" \
  --from="$from" ${@:1} \
  <<<"$(enrichmail \
    "$tmp_file" \
    --generate-html \
    --put-on-imap "INBOX" \
    --add-pixel "$tracking_base_url" \
    --user "$user" \
    --password "$pass" \
    --server "$imap_url" \
    --port "$imap_port")"
