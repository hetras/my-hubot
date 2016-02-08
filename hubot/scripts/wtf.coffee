# Description:
#   Automate environment creation and deployments
#
# Commands:
#   hubot wtf - relax, don't do  it
#

replies = [':japanese_ogre:', ':troll:', ':neckbeard:']

module.exports = (robot) ->
  robot.respond /wtf$/i, (r) ->
    r.send r.random replies
