#! /bin/bash
declare -A LIBS
declare -A ADDR

find_loaded_libs()
{   
    local i=0
    echo "finding loaded libs..."
    cat /proc/$1/maps | grep -E "/libc" | awk '{print $6}' | sort -ur | 
    while read lib; 
    do
        LIBS[$i]+="$lib"
        let i++
    done 
}

find_base_of_lib()
{
    local i=0
    cat /proc/$1/maps | grep -F "$2" |
    while read line;
    do
        base_addr=$(echo $line | awk '{print $1}' | cut -c1-12)
        if [ $i -eq 0 ]
        then
            ADDR[$2]=$base_addr
        elif (( $(( 16#${ADDR[$2]} )) > $(( 16#$base_addr )) ))
        then
            ADDR[$2]=$base_addr 
        fi
        let i++
    done
}

display_libc()
{
    STARTTIME=$(date +%s)
    SLEEPLEN=1
    sleep 1 2>/dev/null &
    PID=$!
    find_loaded_libs $PID
    for(( i=0; i<${#LIBS[@]}; i++ ));
    do
        lib="${LIBS[$i]}"
        find_base_of_lib $PID "$lib"
        addr="${ADDR[$lib]}"
        echo "$lib has base address at: $addr"
    done
}