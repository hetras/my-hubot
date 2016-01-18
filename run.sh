#! /bin/bash
token=`grep HUBOT_SLACK_TOKEN /etc/environment`
aws_creds=`grep ANSIBLE_AWS_KEY_FILE /etc/environment`
export ${token}
export ${aws_creds}

# run hubot controlled by supervisord
cd hubot
bin/hubot -a slack

# docker try by crodemeyer was never fully functional - comment out by Benni
#docker run --rm -it -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" hubot
