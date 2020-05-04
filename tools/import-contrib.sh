#!/bin/bash
#
#  import-contrib
#
#  Imports i3blocks-contrib blocklets and creates packages
#  for use by the i3bb-packages-main repository.
#
#  Copyright (c) 2018 Beau Hastings. All rights reserved.
#  License: GNU General Public License v2
#
#  Author: Beau Hastings <beau@saweet.net>
#  URL: https://github.com/hastinbe/i3bb-packages-tools

CONTRIB_REPO=https://github.com/vivien/i3blocks-contrib
CONTRIB_DIR=./i3blocks-contrib
PACKAGE_DIR=../packages

if [ -d "$CONTRIB_DIR" ]; then
    cd "$CONTRIB_DIR"
    git pull origin master
else
    git clone "$CONTRIB_REPO" "$CONTRIB_DIR"
fi

[ $? -eq 0 ] || exit

for i in "$CONTRIB_DIR"/*
do
    if [ -d "$i" ]; then
        package=$(basename "$i")

        if [ ! -f "$i/i3blocks.conf" ]; then
            echo "Skipping $package; no example i3blocks.conf.."
            continue
        fi

        description=$(awk -F ' | ' "/link:${package}\[\]/{print substr(\$0, index(\$0, \$4))}" "$CONTRIB_DIR/README.adoc")

        cat << EOF > "$PACKAGE_DIR/$package"
type = blocklet
repository = $CONTRIB_REPO
subdirectory = $package
description = $description
EOF

    fi
done
