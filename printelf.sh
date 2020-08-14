#! /bin/bash

#************************************************#
#					printelf.sh					 #
#			written by Braxton Marshall			 #
#					Aug 01, 2020				 #
#												 #
#		Display contents of ELF formatted files	 #
#************************************************#

source plt.sh
source libs.sh

usage()
{
	echo "usage: printelf <option(s)> elf-file"
	echo " Display information about the contents of ELF formatted files"
	echo " Options:"
	echo -e "\t -a\t 		Equivalent to: -H -S -g"
	echo -e "\t -g --got\t 	Display LibC functions in the Global Offset Table"
	echo -e "\t -H\t 		Display Elf File Header Information"
	echo -e "\t -L\t 		Display base address of loaded LibC"
	echo -e "\t -S\t 		Display Section Headers"
}

### Main Logic ###
if [ ! -n "$1" ]
then
	usage
	exit
elif [ $# -eq 1 ]
then
	usage
	exit
fi

args="$#"
filename="${@: -1}"
PID=$!
init $filename

while [ "$1" != "" ]; do
	case $1 in
		-a )				display_elf_h
							echo "------------------------------"
							display_shs
							echo "------------------------------"
							parse_got_for_symbols $filename
							exit
							;;
		-g | --got )		parse_got_for_symbols $filename
							;;

		-H )				display_elf_h
							;;	

		-L | --libc )		display_libc
							;; 

		-S )				display_shs
							exit
							;;

		-h | --help )		usage
							exit
							;;

		* )					exit 
	esac
	shift
done

exit
