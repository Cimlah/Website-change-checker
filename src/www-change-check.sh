#! /bin/bash

# - [ ] Website list as an argument or pass a file to argument
# - [ ] Check interval
# - [ ] Browser
# - [ ] Stop checking after detecting first change
# - [ ] Display info about change on screen or in save to file instead of showing the website in browser
# - [ ] Help page

function helpPage() {
    echo "Help page"
}

websites=
check_interval=600
browser=
first_change_stop=false
behaviour="browser"

if [ $# -eq 0 ]; then
    helpPage
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
    -w | --websites)
        shift
        websites=$1
        ;;
    -c | --check-interval)
        shift
        check_interval=$1
        ;;
    -b | --browser)
        shift
        browser=$1
        ;;
    -s | --first-change-stop)
        shift
        first_change_stop=true
        ;;
    -B | --behaviour)
        shift
        behaviour=$1
        ;;
    *)
        echo "Error"
        exit 1
        ;;
    esac

    shift
done

# echo $websites
# echo $check_interval
# echo $browser
# echo $first_change_stop
# echo $behaviour

are_arguments_valid=true
function checkArguments() {
    declare validity=(
        ["w"]=true
        ["c"]=true
        ["b"]=true
        ["B"]=true
    )

    [[ ($check_interval -lt 1) || ($check_interval =~ ^[^0-9]+$) ]] && validity["c"]=false && echo "Check interval invalid"
    ! [[ $browser =~ ^((S|s)afari|(C|c)hrome|(F|f)irefox)$ ]] && validity["b"]=false && echo "Wrong browser chosen. Only 'Safari', 'Chrome' and 'Firefox' are supported"
    ! [[ $behaviour =~ ^((B|b)rowser|(S|s)creen|(F|f)ile)$ ]] && validity["B"]=false && echo "Wrong behaviour chosen. Only 'browser', 'screen' and 'file' are supported"
 
    if [[ -f "$websites" ]]; then
        websites_content=$(cat "$websites")
    else
        websites_content="$websites"
    fi

    old_ifs=$IFS
    IFS=','
    read -ra websites_arr <<< "$websites_content"
    IFS=$old_ifs
    for idx in "${!websites_arr[@]}"; do
        if ! [[ "${websites_arr[$idx]}" =~ ^https?:// ]]; then
            echo "Wrong URL in $((idx+1)). element"
            validity["w"]=false
        fi
    done

    for el in "${!validity[@]}"; do
        if [[ "${validity[$el]}" == false ]]; then
            are_arguments_valid=false
        fi
    done
    if [[ $are_arguments_valid == false ]]; then
        exit 1
    fi
}
checkArguments