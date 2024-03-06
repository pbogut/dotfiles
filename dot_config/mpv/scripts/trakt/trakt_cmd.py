#!/usr/bin/env python
import argparse
import json
import os
import subprocess

import guessit
import six
from trakt import Trakt, objects

parser = argparse.ArgumentParser(
    description="Toggle between visible workspaces.")

parser.add_argument("--name", dest="name", help="file name", default=False)
parser.add_argument(
    "--progress",
    dest="progress",
    help="watch progress percentage",
    default="100",
)
parser.add_argument(
    "--history",
    dest="history",
    action='store_const',
    help="show history",
    const=True,
    default=None,
)
parser.add_argument(
    "--action",
    dest="action",
    help="action (start / pause / stop)",
    default="stop",
)
parser.add_argument(
    "--client-id",
    dest="client_id",
    help="API client id",
    default=None,
)
parser.add_argument(
    "--client-secret",
    dest="client_secret",
    help="API client secret",
    default=None,
)
parser.add_argument(
    "--reauth",
    dest="reauth",
    action='store_const',
    help="Generate new authentication token",
    const=True,
    default=None,
)
parser.add_argument(
    "--auth-file",
    dest="auth_file",
    help="Whrere to save file with token",
    default=None,
)

args = parser.parse_args()

auth_file = args.auth_file
action = args.action
progress = int(args.progress)

if auth_file is None:
    print("Can't figure out where to put authorization, use --auth-file")
    exit(1)

if not args.client_id or not args.client_secret:
    print("Client id and secret are required")
    exit(1)


def on_token_refreshed(_, authorization):
    with open(auth_file, "w") as fifo:
        fifo.write(json.dumps(authorization))
        fifo.flush()
        fifo.close()

    print("Authorization - Token Refreshed: %s" % auth_file)


def authenticate():
    try:
        with open(auth_file, "r") as fifo:
            data = json.loads(fifo.read())
            fifo.close()
        return data
    except:  # noqa - if no file then we are creating one, nothing to do here
        pass

    auth_url = Trakt["oauth"].authorize_url("urn:ietf:wg:oauth:2.0:oob")
    print("Navigate to: %s" % auth_url)
    subprocess.run(["xdg-open", auth_url])
    code = (os.popen(
        'zenity --entry --text="Paste trakt pin here:"').read().strip())
    if code == "":
        code = six.moves.input("Authorization code:")
    if not code:
        exit(1)

    authorization = Trakt["oauth"].token(code, "urn:ietf:wg:oauth:2.0:oob")
    if not authorization:
        exit(1)

    print("Authorization: %s" % auth_file)

    with open(auth_file, "w") as fifo:
        fifo.write(json.dumps(authorization))
        fifo.flush()
        fifo.close()

    return authorization


# Configure
Trakt.configuration.defaults.client(id=args.client_id,
                                    secret=args.client_secret)
if args.reauth:
    try:
        os.remove(auth_file)
    finally:
        authenticate()
        exit(0)

# Authenticate
Trakt.on('oauth.refresh', on_token_refreshed)
Trakt.configuration.defaults.oauth.from_response(authenticate(), refresh=True)

if Trakt['sync/collection'].movies() is None:
    print("Error, can't connect to trakt api")
    exit(2)

if args.history:
    count_items = 20
    list = {}
    for item in Trakt['sync/history'].get(pagination=True, per_page=25):
        # print()
        if isinstance(item, objects.episode.Episode):
            if item.show.title not in list:
                count_items = count_items - 1
                print("%s %s" % (item.show.title, ("S%02dE%02d" % item.pk)))
            list[item.show.title] = True

        if isinstance(item, objects.movie.Movie):
            if item.title not in list:
                count_items = count_items - 1
                print("%s (%s)" % (item.title, item.year))
            list[item.title] = True

        if count_items <= 0:
            exit(2)

    exit(1)

if action not in ["start", "pause", "stop"]:
    print("Action can be one of: start,pause,stop")
    exit(1)

if not args.name:
    print("Name is required")
    exit(1)

result = guessit.guessit(args.name)

if "type" not in result:
    print("Can't figure out what you are watching")
    exit(1)

if result["type"] == "episode":
    show = {}
    episode = {"season": "1"}

    if "episode" in result:
        episode["number"] = result["episode"]
    if "episode_title" in result:
        episode["title"] = result["episode_title"]
    if "season" in result:
        episode["season"] = result["season"]
    if "year" in result:
        show["year"] = result["year"]
    if "title" in result:
        show["title"] = result["title"]

    print("Request sent:", end=" ")
    print({
        "action": action,
        "show": show,
        "episode": episode,
        "progress": progress
    })

    response = Trakt["scrobble"][action](show=show,
                                         episode=episode,
                                         progress=progress)
    print("Response received:", end=" ")
    print(response, end="")

if result["type"] == "movie":
    movie = {}
    if "year" in result:
        movie["year"] = result["year"]
    if "title" in result:
        movie["title"] = result["title"]

    print("Request sent:", end=" ")
    print({"action": action, "movie": movie, "progress": progress})

    response = Trakt["scrobble"][action](movie=movie, progress=progress)
    print("Response received:", end=" ")
    print(response, end="")
