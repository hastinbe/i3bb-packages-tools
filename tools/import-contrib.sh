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

init_colors() {
    if [[ -t 1 ]]; then
        local -i num_colors
        num_colors=$(tput colors)

        # Only enable colors if the terminal supports at least 8 colors
        if [[ -n "$num_colors" ]] && (( num_colors >= 8 )); then
            NORMAL="$(tput sgr0)"
            RED="$(tput setaf 1)"
            GREEN="$(tput setaf 2)"
            YELLOW="$(tput setaf 3)"
            MAGENTA="$(tput setaf 5)"
        fi
    fi
}

success() {
    echo -e "${GREEN}${CHECKMARK}${NORMAL} $*"
}

fail() {
    echo -e "${RED}${XMARK}${NORMAL} $*"
}

info() {
    echo -e "${YELLOW}${OMARK}${NORMAL} $*"
}

error() {
    echo "${RED}$*${NORMAL}"
}

clone_or_pull_repo() {
    if [[ -d "$CONTRIB_DIR" ]]; then
        read -n 1 -r -p "Update i3blocks-contrib? "
        echo
    
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            { 
                cd "$CONTRIB_DIR" || exit 1
                git pull origin master || exit 1
            }
        fi
    else
        git clone "$CONTRIB_REPO" "$CONTRIB_DIR" || exit 1
    fi
}

create_package() {
    local -r \
        path=${1:?$(error 'Path is required')} \
        directory=${2:?$(error 'Directory is required')} \
        repo=${3:?$(error 'Repository is required')} \
        description=${4}

    cat <<- EOF > "$path"
type = blocklet
repository = "$repo"
subdirectory = "$directory"
description = "$description"
EOF
}

create_config_from_markdown() {
    local -r input=${1:?$(error 'Input file is required')} \
             output=${2:?$(error 'Output file is required')}
    local -a config 

    if mapfile config < <(gawk -f "extract-markdown-fenced-codeblock.awk" "$input"); then
        # Check if we have INI-like named section, for loose validation that we got what we're looking for
        if [[ ${config[0]} =~ ^\[.*\]?$ ]]; then 
            echo "${config[*]}" > "$output"
            return 0
        fi
    else
        [[ -n "$VERBOSE" ]] && fail "'$input' doesn't contain a valid i3blocks blocklet section"
    fi

    return 1
}

main() {
    declare CONTRIB_REPO=https://github.com/vivien/i3blocks-contrib \
            CONTRIB_DIR=./i3blocks-contrib \
            PACKAGE_DIR=../packages \
            CHECKMARK=✓ \
            XMARK=✗ \
            OMARK=● \
            NORMAL \
            RED \
            GREEN \
            YELLOW \
            MAGENTA

    init_colors
    
    clone_or_pull_repo
        
    for blocklet in "$CONTRIB_DIR"/*; do
        if [[ -d "$blocklet" ]]; then
            package=${blocklet##$CONTRIB_DIR/}

            [[ -n "$VERBOSE" ]] && info "Processing $blocklet..."
    
            if ! [[ -f "$blocklet/i3blocks.conf" ]]; then
                if [[ -f "$blocklet/README.md" ]]; then
                    if create_config_from_markdown "$blocklet/README.md" "$blocklet/i3blocks.conf"; then
                        success "Created ${MAGENTA}$blocklet/i3blocks.conf${NORMAL}"
                    else
                        fail "Skipping ${MAGENTA}$package${NORMAL}; failed to create i3blocks.conf from README.md..."
                        continue
                    fi
                else
                    info "Skipping ${MAGENTA}$package${NORMAL}; Can't find or create i3blocks.conf..."
                    continue
                fi
            fi
    
            description=$(awk -F ' | ' "/link:${package}\[\]/{print substr(\$0, index(\$0, \$4))}" "$CONTRIB_DIR/README.adoc")
    
            [[ -d "$PACKAGE_DIR" ]] || mkdir "$PACKAGE_DIR"

            [[ -n "$VERBOSE" ]] && info "Creating package $package"
            create_package "$PACKAGE_DIR/$package" "$package" "$CONTRIB_REPO" "$description" &&
                success "Created package ${MAGENTA}$package${NORMAL}"
        fi
    done
}

main

exit 0
