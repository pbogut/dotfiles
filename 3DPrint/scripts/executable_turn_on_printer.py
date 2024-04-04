#!/usr/bin/python3 -E
import requests
import os
import re
import time
from sys import argv
from subprocess import call
from subprocess import check_output

def get_option(source, name, default=None):
    m = re.search('^' + name + '=(.*)$', source, re.MULTILINE)
    if m is not None:
        return m.group(1)
    else:
        return default

file_name = argv[1] if len(argv) == 2 else None

printer_notes = os.getenv('SLIC3R_PRINTER_NOTES').replace('\\n', '\n').strip('"')

printer_name = get_option(printer_notes, 'NAME', '')
# exit if only exporing gcode
if file_name.find(os.getenv('TMPDIR') or '/tmp') != 0:
    exit(0)

printer_name = get_option(printer_notes, 'NAME', '')
host = get_option(printer_notes, 'MOONRAKER_HOST', '7125')
api_port = get_option(printer_notes, 'MOONRAKER_PORT', '7125')

call(['ssh', 'pi@' + host, '-t', './octopi-klipper/scripts/prepare.sh', printer_name, api_port])
