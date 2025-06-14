#! /bin/bash

# - [X] Website list as an argument or pass a file to argument
# - [X] Check interval
# - [X] Browser
# - [X] Stop checking after detecting first change
# - [X] Display info about change on screen or in save to file instead of showing the website in browser
# - [ ] Help page

function helpPage() {
    echo "Help page"
}

websites=
check_interval=600
browser="Safari"
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
        first_char=$(echo "${1:0:1}" | tr '[:lower:]' '[:upper:]')
        rest_chars=$(echo "${1:1}" | tr '[:upper:]' '[:lower:]')
        browser="${first_char}${rest_chars}"
        ;;
    -s | --first-change-stop)
        shift
        first_change_stop=true
        ;;
    -B | --behaviour)
        shift
        first_char=$(echo "${1:0:1}" | tr '[:lower:]' '[:upper:]')
        rest_chars=$(echo "${1:1}" | tr '[:upper:]' '[:lower:]')
        behaviour="${first_char}${rest_chars}"
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
        # Read file content and store in array, split by newlines
        websites_arr=()
        while IFS= read -r line; do
            websites_arr+=("$line")
        done < "$websites"
    else
        # Split by commas for direct input
        old_ifs=$IFS
        IFS=','
        read -ra websites_arr <<< "$websites"
        IFS=$old_ifs
    fi

    # Validate each URL
    for idx in "${!websites_arr[@]}"; do
        # Trim whitespace from the URL
        websites_arr[$idx]=$(echo "${websites_arr[$idx]}" | xargs)
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


if [[ ! -d "./temp" ]]; then mkdir temp; fi
for idx in "${!websites_arr[@]}"; do
    curl -s "${websites_arr[$idx]}" > "./temp/${idx}-orig.html"
done

while true; do
    for idx in "${!websites_arr[@]}"; do
        if [[ -f "./temp/${idx}-new.html" ]]; then
            rm ./temp/"${idx}"-orig.html && \
            mv ./temp/"${idx}"-new.html ./temp/"${idx}"-orig.html
        fi
    done

    changed_websites=()
    for idx in "${!websites_arr[@]}"; do
        curl -s "${websites_arr[$idx]}" > "./temp/${idx}-new.html"
        difference=$(diff ./temp/"${idx}"-new.html ./temp/"${idx}"-orig.html)
        if [[ ${#difference} -gt 0 ]]; then
            changed_websites+=("${websites_arr[$idx]}")
        fi
    done

    case $behaviour in
    Browser)
        for idx in "${!changed_websites[@]}"; do
            case $browser in
            Chrome) # Need to change "Chrome" to "Google Chrome"
                open -a Google\ Chrome "${changed_websites[$idx]}"
                ;;
            *)
                open -a "$browser" "${changed_websites[$idx]}"
                ;;
            esac
        done
        ;;
    Screen)
        for idx in "${!changed_websites[@]}"; do
            echo "$(date) - ${changed_websites[idx]} changed!"
        done
        ;;
    *)
        for idx in "${!changed_websites[@]}"; do
            echo "$(date) - ${changed_websites[idx]} changed!" >> ./log.txt
        done
        ;;
    esac

    if [[ $first_change_stop = true && ${#changed_websites[@]} -gt 0 ]]; then exit 0; fi

    sleep "$check_interval"
done