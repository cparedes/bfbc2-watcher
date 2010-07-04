#!/bin/sh
#
# Author: Christian Paredes
# Initial Date: 03/29/2010
# Last Edit Date: 04/08/2010
# Version: 0.21
#
# Changes:
#
# 0.21: Email being sent had an old variable being used as part of the
# email subject, this has been changed to reflect the IP address
# entered in as a command line argument.
#
# 0.2: Fixed up previous errors with the script, seems that /bin/sh
# on NetBSD didn't like piped commands on separate lines.  I've thrown
# everything on a single line.  Also changed the script so that it takes
# an IP address as a command line argument.
# 
# License: New BSD License
#
# Copyright (c) 2010, Christian Paredes 
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#	* Redistributions of source code must retain the above copyright
#	  notice, this list of conditions and the following disclaimer.
#	* Redistributions in binary form must reproduce the above copyright
#	  notice, this list of conditions and the following disclaimer in the
#	  documentation and/or other materials provided with the distribution.
#	* Neither the name of redbluemagenta nor the
#	  names of its contributors may be used to endorse or promote products
#	  derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL CHRISTIAN PAREDES BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Description:
#
# This checks the population of the BF:BC2 server by grabbing the GameTracker
# page for the server, doing a grep for HTML_num_players, then checks if the
# integer inside the <span> tag is greater than 4 people.  If so, email
# server admin.
#
# Usage:
#
# ./check_bfbc2_pop.sh <ip address>
# 
# Example: ./check_bfbc2_pop.sh 127.0.0.1
#
# Motivation:
# 
# Instead of needlessly checking the game server population continuously through
# the day, you can simply be emailed when the server population hits a certain
# threshold, so that you can actively administer the server when there is a
# nontrivial number of players in the server.

####
# EDIT THE FOLLOWING VARIABLES FOR YOUR OWN SERVER AND EMAIL ADDRESS.
####

# $THRESHOLD: the minimum population number that must be met before you are
# emailed automatically.

THRESHOLD=4

# $MAILTO: admin's email address.

MAILTO="cp@redbluemagenta.com"

####
# END EDITABLE SECTION.  DO NOT EDIT THE LINES BELOW.
####

if [ ! $1 ]
then
	echo "Usage: ./check_bc2_pop.sh <ip address>"
	exit
fi

TMP_OLD="/tmp/bfbc2_pop_$1.cache"

# This group of commands basically grabs the GameTracker page for your server,
# looks for the span tag "HTML_num_players", cuts out all of the surrounding 
# HTML, and outputs the integer that's contained within that tag (which happens 
# to be the current server population)

URL="http://www.gametracker.com/server_info/$1:19567/"

BFBC2_POP=`ftp -V -o - $URL | grep HTML_num_players | awk '{ print $2 }' | cut -d \"\> -f3 | cut -d \<\\span\> -f1 | tr -d \>` 

# Output population info to console if executed in the command line.

echo "Current Server Population for $1: $BFBC2_POP"

# If the file exists, then throw the contents into $BFBC2_POP_OLD.
# Otherwise, set $BFBC2_POP_OLD to -1.

if [ -f $TMP_OLD ]
then
	BFBC2_POP_OLD=`cat $TMP_OLD`
else
	BFBC2_POP_OLD="-1"
fi

# If the current population is equal to the previous population reading,
# then quit the shell script. (Should be replaced by a better heuristic.)

if [ $BFBC2_POP -eq $BFBC2_POP_OLD ]
then
	exit
fi

if [ $THRESHOLD -le $BFBC2_POP ]
then
	echo "Server population is gravy! It's at $BFBC2_POP!" | mail -s "BFBC2 Server Speaking - $1" $MAILTO
fi

echo $BFBC2_POP > $TMP_OLD
