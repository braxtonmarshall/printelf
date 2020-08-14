#! /bin/bash
source elf.sh

# 1 -> file 2 -> string
parse_got_for_symbols()
{
    find_sh $1 ".plt"
    bytes=$(od -h --endian big -v -N $size -j $(($off+16)) $1 | cut -b9- )
    string_found=0
    rel_or_rela=0
    dyn_off_rel=12
    dyn_off_rela=30
    loop=1
    rel_off_off=17
    dynsym_off_off_rel=40
    dynsym_off_off_rela=60
    while [ $string_found -eq 0 ]
    do
        name=""
        rel_off=${bytes:$rel_off_off:2}
        find_sh $1 ".rel.plt" &> /dev/null
        if [ $found -eq 0 ]
        then
            find_sh $1 ".rela.plt" &> /dev/null
            rel_or_rela=1
        fi
        bytes=$(od -h --endian big -v -N $size -j $off $1 | cut -b9-)
        if [ $rel_or_rela -eq 1 ]
        then
            dynsym_index=${bytes:dyn_off_rela:2}
            dynsym_index=$(( 16#$dynsym_index ))
        else
            dynsym_index=${bytes:$dyn_off_rel:2}
            dynsym_index=$(( 16#$dynsym_index ))
        fi
        if [ $dynsym_index -eq 0 ]
        then
            string_found=1
            return
        fi
        find_sh $1 ".dynsym" &> /dev/null
        bytes=$(od -h --endian big -v -N $size -j $off $1 | cut -b9-)
        if [ $rel_or_rela -eq 1 ]
        then
            dynsym_off=$(( dynsym_off_off_rela * $dynsym_index ))
        else
            dynsym_off=$(( dynsym_off_off_rel * $dynsym_index ))
        fi
        strtab_index=${bytes:$dynsym_off+2:2}${bytes:$dynsym_off:2}
        strtab_index=$(( 16#$strtab_index ))
        find_sh $1 ".dynstr" &> /dev/null
        bytes=$(od -h --endian big -v -N $(( $size - $strtab_index)) -j $(($off + $strtab_index)) $1 | cut -b9-)
        sh_name=$(echo -n "${bytes//[[:space:]]/}")
        sh_name=$(echo ${sh_name%%002*})
        sh_name=$(echo ${sh_name%%00*})
        if [ $((${#sh_name} % 2)) -eq 1 ]
        then
            sh_name=$(echo ${sh_name}0)
        fi
        for (( j=0; j<${#sh_name}; j+=2 ));
        do
            ascii=$(echo -e "\x${sh_name:$j:2}")
            name=$name$ascii
        done
        echo "$loop : $name"
        let "dyn_off_rel+=20"
        let "dyn_off_rela+=60"
        let "rel_off_off+=40"
        let "loop+=1"        
    done
}