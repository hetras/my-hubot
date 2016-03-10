# Description:
#   Get the status of hetras systems relevant for public api from ElasticSearch.
#
# Commands:
#   hubot estats - show statistics for the last three days from ElasticSearch
#   hubot estats [days 15] [percentiles 10,20,...] [statuses 200,201,...]

request = require('request')
querystring = require('querystring')

module.exports = (robot) ->

  robot.respond /estats$/i, (r) ->
    request 'http://localhost:5001/api/latency/stats?days=3', (error, response, body) ->
      r.send '\n```\n' + body + '```'
  
  robot.respond /estats (.+)$/i, (r) ->
    input = r.match[1]
    params = {}
    days = input.match(/days\s+(\d+)/i)
    if days
      params.days = days[1]
    percentiles = input.match(/percentiles\s+([0-9,\.]+)/i)
    if percentiles
      params.percentiles = percentiles[1].split(',')
    statuses = input.match(/statuses\s+([0-9,]+)/i)
    if statuses
      params.statuses = statuses[1].split(',')
    # do not use built-in query params of request packet, it encodes params
    # so they cannot be processed by the microservice then
    qs = querystring.encode(params)
    request.get 'http://localhost:5001/api/latency/stats?' + qs, (error, response, body) ->
      r.send '\n```\n' + body + '```'

