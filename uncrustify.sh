#! /bin/bash

set -e

readonly FILES=`find src -name "*.vala" -type f`

for FILE in ${FILES}
do
	echo "uncrusitfy: ${FILE}"
done

echo "press ENTER to continue"
read

for FILE in ${FILES}
do
	cp -f ${FILE} ${FILE}.bak
	uncrustify -l VALA -f ${FILE}.bak -c uncrustify.cfg -o ${FILE} || true
done

