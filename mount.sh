#!/bin/bash

# gamevswap - utility to easily switch between versions of Steam games
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

pushd /home/steamer/RimWorldApp
TARGET=$(readlink -f steamcommon/RimWorld)

# previous version selection
PREV_SEL="$(<selected)"
# version selection from command line, or fall back to previous
SEL="${1:-$PREV_SEL}"
echo "Selecting RimWorld version $SEL"

if findmnt "$TARGET"
then
    if [[ "$PREV_SEL" = "$SEL" ]]
    then
        echo "Selected version already mounted."
        exit 0;
    fi
    fusermount -u "$TARGET"
fi

if
    [[ ! -z "$SEL" ]] && \
    unionfs -o cow changes=RW:mods=RO:"$SEL"=RO "$TARGET"
then
    echo "RimWorld app successfully mounted"
    # save version selection
    echo "$SEL" > selected
else
    echo "Failed to mount"
fi

popd > /dev/null
