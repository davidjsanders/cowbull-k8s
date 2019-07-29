# Call getopt to validate the provided input. 
options=$(getopt -o "s:t:l:c:v:w:" -l "load,delete,source:,target:,lbip:,storage-class:,cowbull-version:,webapp-version:" -- "$args")
if [ $? -eq 0 ] || { 
    short_banner "Incorrect options provided"
    usage
    exit 1
}
