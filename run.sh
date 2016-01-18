#! /bin/bash
token=`grep SLACK /etc/environment`
export ${token}

# run hubot controlled by supervisord
cd hubot
bin/hubot -a slack

# docker try by crodemeyer was never fully functional - comment out by Benni
#docker run --rm -it -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" hubot
