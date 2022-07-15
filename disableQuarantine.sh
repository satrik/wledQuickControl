#!/bin/sh

CURRENTDIR=$PWD
APP="wledQuickControl.app"

cd ${CURRENTDIR}

if [ -d $APP ]; then
    
    xattr -cr $CURRENTDIR/$APP

    echo "$APP should work now :)"

else 

    echo "$APP not found. Make sure to execute this script in the same folder as the app"

fi

exit 0