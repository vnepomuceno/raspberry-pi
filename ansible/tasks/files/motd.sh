#!/bin/bash

let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
let secs=$((${upSeconds}%60))
let mins=$((${upSeconds}/60%60))
let hours=$((${upSeconds}/3600%24))
let days=$((${upSeconds}/86400))
UPTIME=`printf "%d days, %02dh%02dm%02ds" "$days" "$hours" "$mins" "$secs"`

# get the load averages
read one five fifteen rest < /proc/loadavg

echo "$(tput setaf 2)
   .~~.   .~~.         `date +"%A, %e %B %Y, %r"`
  '. \ ' ' / .'        `uname -srmo`$(tput setaf 1)
   .~ .~~~..~.
  : .~.'~'.~. :        OS Name............: `cat /etc/os-release | grep PRETTY_NAME | cut -c 14- | rev | cut -c 2- | rev`
 ~ (   ) (   ) ~       Uptime.............: ${UPTIME}
( : '~'.~.'~' : )      Memory.............: `cat /proc/meminfo | grep MemFree | awk {'print $2/1000'}`MB (Free) / `cat /proc/meminfo | grep MemTotal | awk {'print $2/1000'}`MB (Total)
 ~ .~ (   ) ~. ~       Load Averages......: ${one}, ${five}, ${fifteen} (1, 5, 15 min)
  (  : '~' :  )        Running Processes..: `ps ax | wc -l | tr -d " "`
   '~ .~~~. ~'         IP Addresses.......: `hostname -I | cut -c -12` and `wget -q -O - http://icanhazip.com/ | tail`
       '~'             Weather............: `curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=1&locCode=EUR|UK|UK001|NAILSEA|" | sed -n '/Currently:/ s/.*: \(.*\): \([0-9]*\)\([CF]\).*/\2°\3, \1/p'`
$(tput sgr0)"