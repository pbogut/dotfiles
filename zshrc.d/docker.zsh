#!/bin/bash
#=================================================
# name:   docker.zsh
# author: Pawel Bogut <http://pbogut.me>
# date:   22/07/2017
#=================================================
docker-cleanup(){
    docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
    docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
}
