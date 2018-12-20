# offline imap python script to get advanced config options
# for a start, quick sync with only inbox checking
import subprocess

import os

inbox_only = os.getenv('OFFLINEIMAP_INBOX_ONLY') == "1"

"""
Reads config from local storage
Used mostly for sensitive data like passwords or email address
"""
def get_config(key):
    value = subprocess.Popen("~/.scripts/gpg-config get %s" % key,
                     shell=True, stdout=subprocess.PIPE).stdout.read()
    value = value.strip("\n")

    return value
