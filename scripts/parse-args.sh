eval set -- "$options"
while true; do
    case "$1" in
    -s | --source)
        SOURCE_REGISTRY="$2"
        shift 2
        ;;
    -t | --target)
        TARGET_REGISTRY="$2"
        shift 2
        ;;
    -l | --lbip)
        LBIP="$2"
        shift 2
        ;;
    -c | --storage-class)
        STORAGE_CLASS="$2"
        shift 2
        ;;
    -v | --cowbull-version)
        COWBULL_VERSION="$2"
        shift 2
        ;;
    -w | --webap-version)
        COWBULL_WEBAPP_VERSION="$2"
        shift 2
        ;;
    --load)
        ACTION="load.sh"
        shift
        ;;
    --delete)
        ACTION="delete.sh"
        shift
        ;;
    --)
        shift
        break
        ;;
    esac
done

if [ -z ${LBIP+x} ] || \
   [ -z ${SOURCE_REGISTRY+x} ] || \
   [ -z ${TARGET_REGISTRY+x} ] || \
   [ -z ${STORAGE_CLASS+x} ]
then
    echo
    short_banner "Unable to proceed: missing required argument(s)"
    usage
    exit 1
fi
