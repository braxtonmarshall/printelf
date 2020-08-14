#! /bin/bash
shopt -s lastpipe
declare -A SECTIONS
parse_elf_h()
{
    bytes=$(od -h --endian big -N 64 $1)
    elf_h="${bytes:8:9}"
    bit_format="${bytes:18:2}"
    endianness="${bytes:20:2}"
    file_type="${bytes:58:2}${bytes:56:2}"
    isa="${bytes:63:2}${bytes:61:2}"
    if [ "$bit_format" -eq "01" ];
    then 
        entry_addr="${bytes:83:2}${bytes:81:2}${bytes:78:2}${bytes:76:2}"
        sht_offset="${bytes:111:2}${bytes:109:2}${bytes:106:2}${bytes:104:2}"
        sht_size="${bytes:141:2}${bytes:139:2}"
        strtable_off="${bytes:159:2}${bytes:157:2}"
        sh_num="${bytes:154:2}${bytes:152:2}"
    elif [ "$bit_format" -eq "02" ];
    then 
        entry_addr="${bytes:93:2}${bytes:91:2}${bytes:88:2}${bytes:86:2}${bytes:83:2}${bytes:81:2}${bytes:78:2}${bytes:76:2}"
        sht_offset="${bytes:141:2}${bytes:139:2}${bytes:136:2}${bytes:134:2}${bytes:131:2}${bytes:129:2}${bytes:126:2}${bytes:124:2}"
        sht_size="${bytes:179:2}${bytes:177:2}"
        strtable_off="${bytes:189:2}${bytes:187:2}"
        sh_num="${bytes:184:2}${bytes:182:2}"
    fi
}
# 1 file 
lookup_sh_name()
{   
    name=""
    strtabladdr_off=$(( 16#$sht_offset + (16#$sht_size * 16#$strtable_off) ))
    bytes=$(od -h --endian big -N $(( 16#$sht_size )) -j $strtabladdr_off $1)
    case $bit_format in
        #32bit
        "01")
                strtabladdr="${bytes:63:2}${bytes:61:2}${bytes:58:2}${bytes:56:2}"
                strtablsize="${bytes:73:2}${bytes:71:2}${bytes:68:2}${bytes:66:2}"
        ;;
        #64bit
        "02")
                strtabladdr="${bytes:83:2}${bytes:81:2}${bytes:78:2}${bytes:76:2}"
                strtablsize="${bytes:114:2}${bytes:111:2}${bytes:109:2}${bytes:106:2}${bytes:104:2}"
        ;;
    esac
    sh_name=$(od -h --endian big -N 32 -j $(( 16#$strtabladdr + $ind)) $1 | cut -b9-)
    sh_name=$(echo -n "${sh_name//[[:space:]]/}")
    sh_name=$(echo ${sh_name%%002*})
    sh_name=$(echo ${sh_name%%00*})
    for (( j=0; j<${#sh_name}; j+=2 ));
    do
        ascii=$(echo -e "\x${sh_name:$j:2}")
        name=$name$ascii
    done
}
#1 is file
parse_sht()
{   
    unset SECTIONS
    range=$(( 16#$sh_num ))
    local i
    for (( i=0; i<$range; i++ ));
    do
        sh_off=$(( 16#$sht_offset + (16#$sht_size * $i) ))
        bytes=$(od -h -v --endian big -N $(( 16#$sht_size )) -j $sh_off $1)
        case $bit_format in
            #32bit
            "01")
                ind="${bytes:15:2}${bytes:13:2}${bytes:10:2}${bytes:8:2}"
            ;;
            #64bit
            "02")
                ind="${bytes:15:2}${bytes:13:2}${bytes:10:2}${bytes:8:2}"
            ;;
        esac
        ind="$(( 16#$ind ))"
        if [ $i -eq 0 ];
        then
            ind="$(( $ind + 1 ))"
        fi
        lookup_sh_name $1 $ind
        SECTIONS[$i]+="$name"
    done
}
# 1 file
init()
{
    parse_elf_h $1
    parse_sht $1
}
#1 file 2 stringname
find_sh()
{   
    index=0
    found=0
    local i
    for(( i=0; i<${#SECTIONS[@]}; i++ ));
    do
        if [ "${SECTIONS[$i]}" == $2 ];
        then
            index=$i
            found=1
        fi
    done
    sh_off=$(( 16#$sht_offset + (16#$sht_size * $index) ))
    bytes=$(od -h --endian big -N $(( 16#$sht_size )) -j $sh_off $1)
    sect_attr="${bytes:28:2}"
    if [ "$sect_attr" -eq "06" ];
    then
        echo "$2 section is in memory and executable..."
    elif [ "$sect_attr" -eq "02" ] || [ "$sect_attr" -eq "03" ];
    then
        echo "$2 section is in memory..."
    else
        echo "WARNING: $2 section is not in memory..."
    fi
    case $bit_format in
        #32bit
        "01")
            virt_addr="${bytes:45:2}${bytes:43:2}${bytes:40:2}${bytes:38:2}"
            off="${bytes:63:2}${bytes:61:2}${bytes:58:2}${bytes:56:2}"
            size="${bytes:73:2}${bytes:71:2}${bytes:68:2}${bytes:66:2}"
        ;;
        #64bit
        "02")
            virt_addr="${bytes:68:2}${bytes:66:2}${bytes:63:2}${bytes:61:2}${bytes:58:2}${bytes:56:2}"
            off="${bytes:88:2}${bytes:86:2}${bytes:83:2}${bytes:81:2}${bytes:78:2}${bytes:76:2}"
            size="${bytes:116:2}${bytes:114:2}${bytes:111:2}${bytes:109:2}${bytes:106:2}${bytes:104:2}"
        ;;
    esac
    off="$(( 16#$off ))"
    size="$(( 16#$size ))"
}
display_elf_h()
{
    echo "Elf header: $elf_h"
    echo "Bit format: $bit_format"
    echo "Endianness: $endianness"
    echo "File Type: $file_type"
    echo "ISA: $isa"
    echo "Entry Address: $entry_addr"
    echo "Symbol Header Table Offset: $(( 16#$sht_offset ))"
    echo "Symbol Header Table Size: $(( 16#$sht_size ))"
    echo "Symbol String Table Index: $(( 16#$strtable_off ))"
}
display_shs()
{  
    local i
    for(( i=0; i<${#SECTIONS[@]}; i++ ));
    do
        echo "[$i] : ${SECTIONS[$i]}"
    done
}
