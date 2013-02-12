#!/bin/sh
echo "---link android sdk android-3/android.jar  to . before building---"
ant clean
ant -v compile
rm HasOffersAndroidSDK.jar 
ant jar
java -jar proguard4.6/lib/proguard.jar @library.pro
