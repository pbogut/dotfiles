#!/bin/bash
#sh $* mkdir -p .ssh
cat ~/.ssh/id_rsa.pub | ssh $* 'mkdir -p .ssh; cat >> .ssh/authorized_keys'
ssh $*
