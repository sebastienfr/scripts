#!/bin/bash
#
# File : subdispatch.sh
#
# Goal :
#       dispatch files by their creation date into folders date named subfolders
#       move movies into a 'mov' folder
#       move raw files into a separate 'raw' folder (-raw optional)
#       move rejected raw (without associated jpeg) in a 'reject' folder (-reject optional)
#
# History :
# 29/10/10 Creation (SFR)
# 02/10/10 Add option -raw -mov -reject (SFR)

############################
# debug                    #
############################
#set -x

############################
# declarations             #
############################
PROG_NAME=`basename $0`

# params
INPUT=""
VERBOSE=""
DISPATCH="true"
RAW="false"
REJECT="false"

# extensions
MOVIE_EXT="mov MOV avi AVI mp4 MP4"
RAW_EXT="nef NEF nrw NRW crw CRW cr2 CR2"
JPEG_EXT="jpg JPG jpeg JPEG"
PIC_EXT="$RAW_EXT $JPEG_EXT"
SUPPORTED_EXT="$PIC_EXT $MOVIE_EXT"

# direcetories
MOV_DIR="mov"
RAW_DIR="raw"
REJECT_DIR="reject"

#type de machine
case `uname -s` in
  "Linux")    MACHINE=LNX;;
	CYGWIN*)    MACHINE=LNX;;
	"Darwin")	  MACHINE=MAC;;
	*)          echo "$PROG_NAME: unknown machine type";exit 1;;
esac

############################
# helper fonctions         #
############################

# verbose echo
vecho() {
	if [ "$VERBOSE" = "-v" ] ; then echo "$PROG_NAME: $*" ; fi
}

# help
usage() {
	if [ "$1" != "-h" ] ; then echo "$PROG_NAME: $1 ";fi
	if [ "$2" = "-h" ] ; then
		echo "usage: $PROG_NAME DIR [options] as follows :"
		echo "	[DIR the directory containing the files to work on (ignores other files than JPEG, JPG, NEF, MOV, AVI)]"
		echo "	[by default creates a directory dated YYYY - MMDD with all same dated files and a mov folder with the movies]"
		echo "	[-raw : move raw files to a separate subfolder called : raw ]"
		echo "	[-reject : move raw files without associated jpeg to a separate subfolder called : reject]"
	fi
	exit 1
}

# parse options and parameters
param() {
    while [ $# -gt 0 ]
        do case $1 in
		-raw) RAW="true";DISPATCH="false";;
		-reject) REJECT="true";DISPATCH="false";;
    -h) usage -h -h;;
		-v) VERBOSE="-v";;
		*) INPUT="$INPUT $1";;
        esac
	shift
    done
}

# check directory is existing
createdir() {
	if [ ! -d "$1" ]; then
		mkdir "$1"
	fi
}

# get file date in YYYY - MMDD format
getdate() {
	# mac os
	if [ "$MACHINE" = "MAC" ]; then
		DATE_DIR=`stat -f "%m" "$1"`
		echo `date -j -f "%s" "$DATE_DIR" "+%Y - %m%d"`
	# linux	
	else 
		DATE_DIR=`stat -c %y "$1" | awk '{printf $1}'`
		echo `date -d "$DATE_DIR" +"%Y - %m%d"`
	fi
}

# get file extension
getext() {
	echo $1 | awk -F "." '{print $NF}'
}

# get filename without extension
getbasename() {
	echo ${1%.*}
}

# true if a file $1 has an extension in list $2
hasext() {
	RET="false"
	for EXT in $2; do
		if [ "$(getext $1)" = "$EXT" ] ; then
			RET="true"
			break;
		fi;
	done
	echo "$RET"
}

# true if is a picture
ispicture() {
	echo $(hasext "$1" "$PIC_EXT")
}

# true if is a raw
israw() {
	echo $(hasext "$1" "$RAW_EXT")
}

# true if is a movie
ismovie() {
	echo $(hasext "$1" "$MOVIE_EXT")
}

############################
# main fonctions           #
############################
# dispatch files by their dates into subfilders
# put movies in a mov folder
dispatch() {
	cd "$1"
	for FILE in `ls`; do
		if [ -f "$FILE" ]; then
			# file date
			DATE_DIR=$(getdate "$FILE")

			# if file is a movie create subdir
			if [ "$(ismovie "$FILE")" = "true" ]; then
				vecho "	moving movie $FILE to $DATE_DIR/$MOV_DIR"
				# create directory is necessary
				createdir "$DATE_DIR"
				createdir "$DATE_DIR/$MOV_DIR"
				mv "$FILE" "$DATE_DIR/$MOV_DIR"
			elif [ "$(ispicture "$FILE")" = "true" ]; then
				vecho "	moving picture $FILE to $DATE_DIR"
				# create directory if necessary
				createdir "$DATE_DIR"
				mv "$FILE" "$DATE_DIR"
			#else
				#vecho "	file $FILE in directory $1 ignored (only JPEG, JPG, NEF, MOV and AVI are handled)" 
			fi;			
		fi;
	done
}

# move all raw files in a 'raw' directory
raw () {
	cd "$1"
	for FILE in `ls`; do
		if [ -f "$FILE" ]; then
			# for all raw files move them into the raw directory
			if [ "$(israw "$FILE")" = "true" ]; then
				vecho "	moving raw $FILE to $RAW_DIR"
				createdir "$RAW_DIR"
				mv "$FILE" "$RAW_DIR"
			#else
				#vecho "	ignoring file $FILE"
			fi;
		fi;
	done
}

# move all raw files without associated jpeg into a 'reject' folder 
reject () {
	cd "$1"
	for FILE in `ls`; do
		if [ -f "$FILE" ]; then
			# for all raw files
			# if jpeg files exists
			# keep the file
			# if not move it to 'reject' folder
			if [ "$(israw "$FILE")" = "true" ]; then
				if [ ! -f "`getbasename $FILE`.jpg" -a ! -f "`getbasename $FILE`.JPG" -a ! -f "`getbasename $FILE`.jpeg" -a ! -f "`getbasename $FILE`.JPEG" ]; then
					vecho "	file $FILE has no relative jpg, file rejected and moved to $REJECT_DIR"
					createdir "$REJECT_DIR"
					mv "$FILE" "$REJECT_DIR"
				#else
					#vecho "	raw $FILE is valid and kept"
				fi;
			#else
				#vecho "	ignoring non raw file $FILE"
			fi;
		fi;
	done
}

# move all movie files into a 'mov' folder
movie () {
	cd "$1"
	for FILE in `ls`; do
		if [ -f "$FILE" ]; then
			# for all movie files move them into mov folder
			if [ "$(ismovie "$FILE")" = "true" ]; then
				vecho "	moving file $FILE to directory $MOV_DIR"
				createdir "$MOV_DIR"
				mv "$FILE" "$MOV_DIR"
			#else
				#vecho "	ignoring non movie file $FILE"
			fi;				
		fi;
	done
}

############################
# main processing          #
############################

# args parsing
param $*

# trim input to handle space in the name
INPUT=`echo $INPUT`

# if no folder is provided exit
if [ -z "$INPUT" ] ; then
		echo "$PROG_NAME: no input directory provided"
		exit 1
fi;
if [ ! -d "$INPUT" ] ; then
		echo "$PROG_NAME: $INPUT directory does not exist"
		exit 1
fi;

# convert to absolute path
CURRENT_PATH=`pwd`
cd "$INPUT"
INPUT=`pwd`
cd "$CURRENT_PATH"

vecho "starting processing... ["`date`"]"
# dispatch and movies
if [ "$DISPATCH" = "true" ] ; then
	vecho "dispatching pictures and movie(s) contained in $INPUT to dedicated subfolders..."
	dispatch "$INPUT"
else
	# reject raw first
	if [ "$REJECT" = "true" ] ; then
		vecho "removing rejected raw(s) in $INPUT ..."
		reject "$INPUT"
	fi;

	# move remaining raws into the 'raw' folder if needed
	if [ "$RAW" = "true" ] ; then
		if [ "$REJECT" = "true" ] ; then
			vecho "moving raw(s) from in $INPUT to separate raw directory..."
		else
			vecho "moving non rejected raw(s) from in $INPUT to separate raw directory..."
		fi;
		raw  "$INPUT"
	fi;
fi;

vecho "end processing...["`date`"]"
exit 0
