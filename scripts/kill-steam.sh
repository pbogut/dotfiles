#!/usr/bin/env bash
#=================================================
# name:   kill-steam
# author: author <author_contact>
# date:   16/09/2023
#=================================================
kill -9 $(ps aux | grep steam | grep -v kill | awk '{print $2}')
