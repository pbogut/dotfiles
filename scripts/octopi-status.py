#!/bin/env python3
import requests
import os
import json
import time
import cachemere
from sys import argv
from subprocess import call


session = cachemere.start('octopi-status', autosave=True)

click = argv[1] if len(argv) == 2 else False


def nice_time(seconds):
    h = int(time.strftime('%H', time.gmtime(seconds)))
    m = int(time.strftime('%M', time.gmtime(seconds)))
    s = int(time.strftime('%S', time.gmtime(seconds)))

    if h > 0:
        return str(h) + 'h ' + str(m) + 'm'
    elif m > 0 and m < 5:
        return str(m) + 'm ' + str(s) + 's'
    elif m > 0:
        return str(m) + 'm'
    else:
        return str(s) + 's'


api_url = os.getenv('OCTOPI_URL')
api_key = os.getenv('OCTOPI_API')

color = '#FFFFFF'
headers = {'X-Api-Key': api_key}
j = requests.get(api_url + '/api/job', headers=headers)
p = requests.get(api_url + '/api/printer', headers=headers)

data = j.json()
if str(click) == "dump":
    print(p.text)
    print(j.text)

try:
    printer = p.json()
    bed_temp = round(printer['temperature']['bed']['actual'])
    tool_temp = round(printer['temperature']['tool0']['actual'])
except:
    bed_temp = None
    tool_temp = None

if 'display' in data['job']['file']:
    file_name = data['job']['file']['display']
else:
    file_name = data['job']['file']['name']

progress = data['progress']['completion']
progress = round(progress) if progress else 0

state = data['state']

if state.find('Offline') == 0:
    state = 'Offline'
elif state.find('Online') == 0:
    state = 'Online'
elif state.find('Operational') == 0:
    state = 'Ready'
elif state.find('Printing') == 0:
    state = 'Printing'
elif state.find('Error') == 0:
    state = 'Error'
    color = '#ff0000'

message = None

if click == "1" and (state == 'Offline' or state == 'Error'):
    call(['ssh', 'pi@192.168.0.107', '-t', 'switch.sh', '3', 'on'])
    time.sleep(2)
    requests.post(api_url + '/api/connection',
                  headers=headers, json={'command': 'connect'})

if click == "2" and state != 'Printing':
    r = call(['zenity', '--width=300', '--question',
              '--text=Are you sure you want to shut down printer?'])
    if str(r) == "0":
        call(['ssh', 'pi@192.168.0.107', '-t', 'switch.sh', '3', 'off'])

if click == "3":
    call(['browser', 'http://192.168.0.107/#control'])


time_passed = nice_time(data['progress']['printTime'])
time_left = nice_time(data['progress']['printTimeLeft'])
time_last_print = nice_time(data['job']['lastPrintTime'])

if progress == 100 and file_name and state != 'Printing' and progress != session.get('last_progress'):
    session.set('last_progress', progress)
    message = "Print finished!\n" + file_name + ': ' + \
        str(progress) + '%' + "\nTotal time: " + \
        time_last_print
    call(['notify-send', '-i', 'printer-printing', message])

if state == 'Printing':
    session.set('last_progress', None)
    message = file_name + ': ' + \
        str(progress) + '% (' + time_passed + ' / ' + time_left + ')'

if not message:
    message = state

color = "#e4fce4" if progress >= 50 else color
color = "#d0fbd0" if progress >= 65 else color
color = "#a6f7a6" if progress >= 75 else color
color = "#67f267" if progress >= 85 else color
color = "#26ec26" if progress >= 95 else color
color = "#06ea06" if progress >= 99 else color

if bed_temp and tool_temp:
    message = message + ' (B:' + str(bed_temp) + '° T:' + str(tool_temp) + '°)'

response = {'full_text': ' ' + message, 'color': color}

print(json.dumps(response))
