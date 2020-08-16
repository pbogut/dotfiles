#!/bin/env python

from otpauth import OtpAuth
import base64
import os
import sys
from urllib import parse


def b32pad(secret):
    padding = ''
    if len(secret) % 8 == 2:
        padding = "======"
    if len(secret) % 8 == 4:
        padding = "===="
    if len(secret) % 8 == 5:
        padding = "==="
    if len(secret) % 8 == 7:
        padding = "="

    return secret + padding


def get_code(secret):
    secret = base64.b32decode(b32pad(secret.upper()))
    auth = OtpAuth(secret)  # a secret string
    code = auth.totp()  # generate a time based code
    code = str(code).zfill(6)

    return code


accounts = []
just_codes = False
if len(sys.argv) > 1:
    just_codes = True
    accounts = sys.argv[1:]
else:
    with open(os.environ['AUTH_ACCOUNTS_FILE']) as f:
        accounts = f.readlines()


acclist = []
max_len = 0
for account in accounts:
    uri = parse.urlparse(account)
    if uri.scheme == 'otpauth':
        if uri.netloc == 'totp':
            query = parse.parse_qs(uri.query)
            # print(query['secret'][0])
            code = get_code(query['secret'][0])
            max_len = len(uri.path.strip('/')) if len(uri.path.strip('/')) > max_len else max_len
            acclist.append((uri.path.strip('/'), code))

for (name, code) in acclist:
    if just_codes:
        print(code)
    else:
        print(name.ljust(max_len) + "\t" + code)

