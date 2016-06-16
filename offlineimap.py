# offline imap python script to get advanced config options
# for a start, quick sync with only inbox checking
import os

inbox_only = os.getenv('OFFLINEIMAP_INBOX_ONLY') == "1"
