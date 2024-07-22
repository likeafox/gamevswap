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



# cd to game data dir
if ! pushd "apps/$GAME"; then
    fail_msg "No saved versions exist for $GAME"
fi

# previous version selection
PREV_VER="$(<cur)"
# select previous version, if specified version is blank
SELECT_VER="${SELECT_VER:-$PREV_VER}"
if [[ ! -d versions/$SELECT_VER ]]; then
    fail_msg "$GAME version $SELECT_VER branch does not exist."
fi
echo "Selecting $GAME version $SELECT_VER"

#
if findmnt "$TARGET" && [[ "$PREV_VER" = "$SELECT_VER" ]]; then
    echo "Selected version already mounted."
    exit 0;
fi
unmount || exit 1

# delete old changes dir, if any
[[ -d changes ]] && rm -rf "$(readlink -f changes)"
rm changes

# will the user folder be mounted?
MOUNT_USER=$(
    shopt -s nullglob
    shopt -s dotglob
    CONTENTS=(user/*)
    [[ ${#CONTENTS[@]} -gt 0 ]] &&
        echo 'true' ||
        echo 'false'
)

# create changes dir for accumulating changes to game files
ln -s "$(mktemp -d -t gamevswap-XXXXXXXXXX)" changes

# mount
if ! $MOUNT_USER; then
    unionfs -o cow -o nonempty changes=RW:versions/"$SELECT_VER"=RO "$TARGET"
    STATUS=$?
else
    unionfs -o cow changes=RW:versions/"$SELECT_VER"=RO inter &&
    unionfs -o cow -o nonempty inter=RW:user=RO "$TARGET"
    STATUS=$?
    [[ $STATUS = 0 ]] || unmount
fi

#
if [[ $STATUS = 0 ]]; then
    echo "Mounted successfully"
    # save version selection
    echo "$SELECT_VER" > cur
else
    fail_msg "Mount failed"
fi

popd > /dev/null
