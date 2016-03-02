#!/bin/bash
for FILE in *.m2ts; do
   echo ${FILE}
   ffmpeg -i ${FILE} -r 29.97 -vcodec libxvid -s 1024x576 -aspect 16:9 -b 2000k -qmin 3 -qmax 5 -bufsize 4096 -mbd 2 -bf 2 -acodec libmp3lame -ar 48000 -ab 128k -ac 2 ${FILE}.avi
done
