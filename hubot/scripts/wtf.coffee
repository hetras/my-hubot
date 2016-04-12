# Description:
#   Automate environment creation and deployments
#
# Commands:
#   hubot wtf - relax, don't do  it
#

replies = [':japanese_ogre:', ':japanese_goblin:', ':bowtie:', ':rube:', ':glitch_crab:', ':troll:', ':neckbeard:', ':piggy:']

module.exports = (robot) ->
  robot.respond /wtf$/i, (r) ->
    r.send r.random replies
