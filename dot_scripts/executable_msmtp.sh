#!/usr/bin/env bash
tmp_file=$(mktemp)
cat /dev/stdin >"$tmp_file"
set -e
set -o pipefail

from=$(enrichmail --get-from-email "$tmp_file")
acc=${from##*@}

ruby=false

# mutt-pre-process.rb -- adds html version of email using markdown
# mutt-put-on-imap.rb -- puts copy of email on the imap server
# mutt-add-tracking-pixel.rb -- adds tracking pixel
# (because pixel is added after email is placed on imap server,
#  you wont triger pixel event yourself)

if [[ $1 == "--preview" ]]; then
  if $ruby; then
    preview="$(mktemp -d)/email.html"
    mutt-pre-process.rb --html-only <"$tmp_file" >"$preview"
    browser "$preview" >/dev/null 2>&1
  else
    preview="$(mktemp -d)/email.html"
    enrichmail --html-preview "$tmp_file" >"$preview"
    # enrichmail --html-preview - < "$tmp_file" > "$preview"
    browser "$preview" >/dev/null 2>&1
    # perevent mutt form sending email
  fi
  exit 1
fi

user=$(config "email/$from/user" "$from")
pass=$(config "email/$from/pass")
imap_url=$(config "email/$acc/imap/host")
imap_port=$(config "email/$acc/imap/port" 993)
tracking_base_url=$(config "email/open_tracking/api_url")

if $ruby; then
  # shellcheck disable=2068,3057,2002
  cat "$tmp_file" |
    mutt-pre-process.rb |
    mutt-put-on-imap.rb |
    mutt-add-tracking-pixel.rb |
    msmtp -a "$acc" --passwordeval="config email/$from/pass" --user="$user" --from="$from" ${@:1}
else
  mail=$(enrichmail \
      "$tmp_file" \
      --generate-html \
      --put-on-imap "INBOX" \
      --add-pixel "$tracking_base_url" \
      --user "$user" \
      --password "$pass" \
      --server "$imap_url" \
      --port "$imap_port")

  # shellcheck disable=2068,3057,2002
  msmtp -a "$acc" \
    --passwordeval="config email/$from/pass" \
    --user="$user" \
    --from="$from" ${@:1} \
    <<<"$mail"
fi
