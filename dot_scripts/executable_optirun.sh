#!/bin/bash
#=================================================
# name:   primusrun.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   24/06/2017
#=================================================
export PRIMUS_libGLa='/usr/$LIB/libGL.so.1'
echo optirun "$@" > /tmp/optirun.log
export >> /tmp/optirun.log
optirun "$@" >> /tmp/optirun.log
