#!/bin/sh

set -e

mkdir -p src
cd src

git clone git://github.com/tomfitzhenry/dotfiles.git
cd dotfiles
./install
