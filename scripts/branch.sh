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



# ensure version selection
if [[ -z $SELECT_VER ]]; then
    echo "You must specify version tag when branching."
    echo "Failed to create branch."
    exit 1;
fi

# cd to game data dir, and ensure required directories exist
mkdir -p "apps/$GAME"
pushd "apps/$GAME"
mkdir -p inter user versions

#
if [[ -d versions/$SELECT_VER ]]; then
    echo "Cannot create branch; it already exists."
    exit 1;
fi

# determine branch source to copy from
INTER="$(pwd)"/inter
BRANCH_SOURCE="$(findmnt "$INTER" > /dev/null && echo "$INTER" || echo "$TARGET")"

# create branch!
cp -PpR "$BRANCH_SOURCE" versions/"$SELECT_VER" &&
echo "Branch $SELECT_VER successfully created."
echo "$SELECT_VER" > cur

# ensure game is unmounted
fusermount -u "$TARGET"
fusermount -u inter

#
popd > /dev/null

# mount new branch
source scripts/mount.sh
