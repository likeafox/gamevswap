#!/bin/bash

# This file is part of gamevswap, a utility to easily switch between
# versions of Steam games.
#
# Copyright (c) 2020  Jason Forbes, <contact@jasonforbes.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.



# cd to script directory
cd "$( dirname "${BASH_SOURCE[0]}" )"

# test for existence of this script
if [[ ! $(head gamevswap.sh) == *gamevswap* ]] ; then
    echo "Failed to find gamevswap directory"
    exit 1;
fi

# ensure potentially empty directories exist
mkdir -p apps searchdirs

#
if ! command -v unionfs-fuse > /dev/null ; then
    echo "This program requires unionfs-fuse to be installed."
    exit 1;
fi

# validate args
USAGE="Usage:
    $(basename "${BASH_SOURCE[0]}") mount <GAME> [VERSION]
    $(basename "${BASH_SOURCE[0]}") branch <GAME> <VERSION>"
if [[ ! $1 = mount && ! $1 = branch || -z $2 ]] ; then
    echo "$USAGE"
    exit 1;
fi
GAME="$2"
SELECT_VER="$3"

# resolve search paths
DEFAULT_SEARCH="$HOME/.local/share/Steam/steamapps/common"
shopt -s nullglob
SEARCHES=( ./searchdirs/* )
if [[ ${#SEARCHES[@]} = 0 ]]; then
    if [[ ! -d $DEFAULT_SEARCH ]]; then
        echo "Cannot locate any game directories: searchdirs/ contains no links to game libraries, and the default library $DEFAULT_SEARCH does not exist."
        exit 1;
    fi
    SEARCHES=("$DEFAULT_SEARCH")
fi

# resolve game install directiory
for SEARCH in "${SEARCHES[@]}"; do
    [[ -d "$SEARCH/$GAME" ]] && TARGET=$(readlink -f "$SEARCH/$GAME") && break;
done
if [[ -z $TARGET ]]; then
    echo "Game \"$GAME\" not found"
    exit 1;
fi

# exec command
source scripts/${1}.sh
ata