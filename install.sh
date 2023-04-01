#!/bin/sh
cp clone.sh /usr/local/bin/clone
mkdir $HOME/.clone 2>/dev/null
cp config.sh $HOME/.clone
cp -r jobs $HOME/.clone

# Installs clone in /usr/local/bin and copies default jobs and
# config files into ~/.clone
#
# (note: this will overwrite existing files)
