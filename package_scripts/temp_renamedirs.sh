#!/bin/sh

# Very simple, fix all the _64 directories to remove the ending and add _32 to the
# 32-bit directories.

for f in ~/packages/*_64 ; do
	if [ -d $f ] ; then
		basename=`basename "$f" _64`
		if [ -d ~/packages/"$basename" ] ; then
			echo "mv ~/packages/\"$basename\" ~/packages/\"${basename}_32\""
			echo "mv ~/packages/\"$basename\"_64 ~/packages/\"${basename}\""
		elif [ -d ~/packages/"$basename"_32 ] ; then
			echo "##folder exists with _32 suffix, nothing to move"
			echo "mv ~/packages/\"$basename\"_64 ~/packages/\"${basename}\""
		else
			echo "!!!No folder without extension - ~/packages/$basename"
			#exit 1
		fi
	else
		echo "Not a directory $f"
	fi
done
				
