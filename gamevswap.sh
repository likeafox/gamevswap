#!/bin/bash

# This file is part of gamevswap, a utility to easily switch between
# versions of Steam games.
#
# Copyright (c) 2020-2024  Jason Forbes, <contact@jasonforbes.ca>
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



BASENAME=$(basename "${BASH_SOURCE[0]}")
USAGE="gamevswap: is a utility for easily switching between software versions of
games.
(c) 2020-2024 Jason Forbes
This program comes with ABSOLUTELY NO WARRANTY.
Licensed for public use under GPLv3.

Usage:
    $BASENAME mount GAME [VERSION]
    $BASENAME unmount GAME
    $BASENAME branch GAME VERSION

Operating modes:
    mount - Mount a previously saved filesystem state of the specified game.

            VERSION may be omitted, in which case the last successfully
            mounted version will be used. This is useful for auto-mounting
            games in the user log-in script.

    unmount - The opposite of mount; any unsaved changes to the mounted game
            directory will be lost.

    branch - Branches off of the current state of the game directory, creating
            a new save state, using VERSION as the new version tag. The new
            branch is then immediately mounted.

Options:
    <GAME> - Specifies the name of the game to work with. The name is exactly
            identical to the name of the directory the game is installed in.
            gamevswap will search for install directories in all locations
            pointed to by symbolic links in \"./searchdirs/\", or, in the
            default location.

    <VERSION> - Can be any valid unix filename. It is used to tag game
            versions, so they can be saved or recalled."



fail_msg () {
    echo "$1" >&2
    exit 1;
}

# cd to main program directory
MAIN_DIR="$(realpath "` dirname "${BASH_SOURCE[0]}" `")"
cd "$MAIN_DIR"

# test for existence of this script
if [[ ! $(head gamevswap.sh) == *gamevswap* ]] ; then
    fail_msg "Failed to find gamevswap directory"
fi

# ensure potentially empty directories exist
mkdir -p apps searchdirs

#
if ! command -v unionfs-fuse > /dev/null ; then
    fail_msg "This program requires unionfs-fuse to be installed."
fi

# validate args
if [[ ! $1 = mount && ! $1 = branch && ! $1 = unmount || -z $2 ]] ; then
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
        fail_msg "Cannot locate any game directories: searchdirs/ contains no links to game libraries, and the default library $DEFAULT_SEARCH does not exist."
    fi
    SEARCHES=("$DEFAULT_SEARCH")
fi

# resolve game install directory
for SEARCH in "${SEARCHES[@]}"; do
    echo "Searching $SEARCH"
    [[ -d "$SEARCH/$GAME" ]] && TARGET=$(readlink -f "$SEARCH/$GAME") && break;
done
if [[ -z $TARGET ]]; then
    fail_msg "Game \"$GAME\" not found"
fi
echo "Found game at $TARGET"

#
unmount () {
    u () {
        {
            ! findmnt "$1"
        } || {
            fusermount -u "$1"
        } || {
            sleep 1
            sync -f "$1"
            fusermount -u "$1"
        } || {
            fusermount -uz "$1"
            sleep 1
            ! findmnt "$1"
        }
    }
    u "$TARGET" && u "${MAIN_DIR}/apps/$GAME/inter" || {
        echo "unmount() failed." >&2
        return false
    }
}

# exec command
source scripts/${1}.sh
