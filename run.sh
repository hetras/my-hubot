#! /bin/bash
token=`grep HUBOT_SLACK_TOKEN /etc/environment`
aws_creds=`grep ANSIBLE_AWS_KEY_FILE /etc/environment`
export ${token}
export ${aws_creds}

# kill subprocess
function kill_subprocess {
  local PID=${1}
  for child in $(ps -o pid --no-headers --ppid ${PID}); do
    kill_subprocess ${child}
  done
  kill -9 ${PID} > /dev/null 2>&1
}

# run hubot controlled by supervisord
cd hubot
trap 'echo "Killing $PID"; kill_subprocess $PID' TERM INT KILL
bin/hubot -a slack &
PID=$!
wait $PID

# docker try by crodemeyer was never fully functional - commented out by Benni
#docker run --rm -it -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" hubot
