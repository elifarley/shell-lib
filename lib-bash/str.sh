strsplit() { (( $# == 3 )) || { echo "Usage: $FUNCNAME <str> <separator> <outvarname>"; return 1 ;}
  IFS="$2" read -a "$3" <<< "$1"
}

# See https://wiki.bash-hackers.org/syntax/pe#case_modification
titleCase() { set ${*,,}; echo ${*^} ;}
