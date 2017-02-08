dimg() { docker inspect "$1" |grep Image | grep -v sha256: | cut -d'"' -f4 ;}
dstatus() { docker inspect "$1" | grep Status | cut -d'"' -f4 ;}
