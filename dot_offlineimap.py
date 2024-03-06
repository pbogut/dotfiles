# offline imap python script to get advanced config options
# for a start, quick sync with only inbox checking
import subprocess

import os

inbox_only = os.getenv('OFFLINEIMAP_INBOX_ONLY') == "1"
lock_file = os.getenv('HOME') + "/offlineimap.lock"

"""
Reads config from local storage
Used mostly for sensitive data like passwords or email address
"""
def get_config(key):
    value = subprocess.Popen("~/.scripts/gpg-config get %s" % key,
                     shell=True, stdout=subprocess.PIPE).stdout.read()
    value = value.strip("\n".encode())

    return value

def is_locked():
    try:
        open(os.getenv('HOME', '') + "/offlineimap.lock")
        return True
    except IOError:
        return False


if (is_locked()):
    print("Sync is locked with lockfile: " + lock_file)
    exit(0)
