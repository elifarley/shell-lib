[![GitHub tag](https://img.shields.io/github/tag/elifarley/shell-lib.svg?maxAge=2592000)](https://github.com/elifarley/shell-lib)
[![Github All Releases](https://img.shields.io/github/downloads/elifarley/shell-lib/total.svg?maxAge=2592000)](https://github.com/elifarley/shell-lib)

# shell-lib
Library of shell functions

# Bootstrapping
~~~~
set -x
mkdir -p .~/shell-lib
curl -H 'Cache-Control: no-cache' -fsSL https://github.com/elifarley/shell-lib/archive/master.tar.gz | \
tar -zx --strip-components 1 -C .~/shell-lib && \
chmod +x .~/shell-lib/bin/* && PATH="$PWD/.~/shell-lib/bin:$PATH"

test -e target || mkdir -p target 

DEBUG=1 dockerize-project
~~~~
