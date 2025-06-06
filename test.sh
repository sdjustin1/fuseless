#!/bin/bash

if [[ !$LUCEE_VERSION ]]; then
	LUCEE_VERSION=6.2.0.321
fi

if [ -f "java/jars/lucee-light-$LUCEE_VERSION.jar" ]; then
	echo "lucee-light-$LUCEE_VERSION.jar already there, skipping download"
else 
	#download lucee jar
	echo "Downloading lucee-light-$LUCEE_VERSION.jar"
	echo "https://cdn.lucee.org/lucee-light-$LUCEE_VERSION.jar"
	curl --location -o java/jars/lucee-light-$LUCEE_VERSION.jar https://cdn.lucee.org/lucee-light-$LUCEE_VERSION.jar
	cp java/jars/lucee-light-$LUCEE_VERSION.jar test/jars/
fi


cd java

#compile java
gradle build

cd ..

cp java/build/libs/foundeo-fuseless.jar test/jars/

cd test

gradle build

sam local start-api --port 3003 --debug &

SAM_PID=$!


#give it a chance to startup
echo -e "Sleeping for 5...\n"
sleep 5


echo "Running: http://127.0.0.1:3003/assert.cfm"
http_code=$(curl --verbose -s --header "Content-Type: application/json" --request POST --data '{"x":1}' -o /tmp/result.txt -w '%{http_code}' 'http://127.0.0.1:3003/assert.cfm?requestMethod=POST&requestContentType=application/json&requestBody=%7B%22x%22%3A1%7D&contentLength=7';)
echo "Finished with Status: $http_code "
echo -e "\n-----\n"
#output the result
cat /tmp/result.txt

echo -e "\n-----\n"

echo "SAM PID: $SAM_PID"
kill $SAM_PID
ps 

if [ "$http_code" -ne 222 ]; then
	#fail if status code is not 222
	echo "Failed Status Code was not 222"
    exit 1
fi




echo "Testing Events"
echo -e "\n-----\n"

sam local generate-event s3 put > /tmp/test-event.json
echo "Created Test Event"
cat /tmp/test-event.json
sam local invoke FuselessTestEvent --event /tmp/test-event.json 



echo -e "\n-----\n"

echo "DONE TESTING"
pstree
#ensure everything is terminated 
killall sam
ps -f


exit 0




