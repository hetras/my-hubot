# Description:
#   Automate environment creation and deployments
#
# Commands:
#   hubot env - list existing environments on Certification
#   hubot env artifacts - list existing artifacts that could be deployed to environments
#   hubot env update <env> <branch> - update an environment with the latest artifacts from branch
#   hubot env restore <env> - restore Backend DB using the latest production backup - use the "keep" option to keep the current DB
#   hubot env password <enviroment> prints the passwords for each tenant for the requested enviroment
#   hubot env password <environment> <tenantcode> prints the password for the specific tenant for the requested enviroment

request = require('request')
printf = require('printf')
dateformat = require('dateformat')
exec = require('child_process').exec;
async = require('async')
maxWidth = (items, index) -> Math.max (item[index].length for item in items)...

module.exports = (robot) ->

  COSTS_PER_MONTH = 700 * 0.11   # Volumes
  COSTS_PER_HOUR = 0.274 + 0.028 + COSTS_PER_MONTH / 30 / 24 # Instance + ELB + Volumes

  robot.respond /env$/i, (r) ->
    request 'http://localhost:5000/instances', (error, response, body) ->
      instances = JSON.parse(body).sort (a, b) ->
        return if a.Name.toUpperCase() >= b.Name.toUpperCase() then 1 else -1
      now = new Date()
      for i in instances
        started = new Date(i.Started)
        i.Started = dateformat(started, "yyyy-mm-dd HH:MM");
        i.Costs = (now - started) / 1000 / 3600 * COSTS_PER_HOUR
      widthName = maxWidth(instances, "Name")
      widthIP = maxWidth(instances, "InternalIP")
      widthState = maxWidth(instances, "State")
      widthArtifacts = maxWidth(instances, "Artifacts")
      widthTeam = maxWidth(instances, "Team")
      title = printf("%-*s %-*s %-*s %-*s %-*s %-16s\n", "Name", widthName, "IP", widthIP, "State", widthState, "Artifacts", widthArtifacts, "Team", widthTeam, "Started")
      sep = "-".repeat(widthName + widthIP + widthState + widthArtifacts + widthTeam + 16 + 4 + 2) + "\n"
      report = (printf("%-*s %-*s %-*s %-*s %-*s %16s", i.Name, widthName, i.InternalIP, widthIP, i.State, widthState, i.Artifacts, widthArtifacts, i.Team, widthTeam, i.Started) for i in instances)
      r.send "```\n" + title + sep + report.join("\n") + "```\n"

  robot.respond /env a(rtifacts)?$/i, (r) ->
    request 'http://localhost:5000/artifacts', (error, response, body) ->
      artifacts = (a.split('_') for a in JSON.parse(body))
      w = (maxWidth(artifacts, i) for i in [0..2])
      w = (Math.max(w[i], title.length) for title, i in ["Artifact", "Version", "Time"])
      title = printf("%-*s %-*s %-*s\n", "Artifact", w[0], "Version", w[1], "Time", w[2])
      sep = "-".repeat(w[0] + w[1] + w[2] + w.length) + "\n"
      artifacts = (printf("%-*s %-*s %-*s", a[0], w[0], a[1], w[1], a[2], w[2]) for a in artifacts).join("\n")
      r.send "```\n" + title + sep + artifacts + "```\n"

  robot.respond /env u(pdate)? ([^ ]+) ([^ ]+)$/i, (r) ->

    download = (path) -> (callback) -> request "http://localhost:5000/#{path}", (err, res, body) ->
      callback(null, JSON.parse(body))

    validate = (valid, val, name, exact) ->
      matching = valid.filter (x) -> (exact and x.toUpperCase() == val.toUpperCase()) or (not exact and x.toUpperCase().startsWith(val.toUpperCase()))
      if (matching.length == 1)
        return matching[0]
      else if (matching.length < 1)
        r.reply "Please specify a valid #{name} from :\n" + valid.join("\n")
      else if (matching.length > 1)
        r.reply "Which #{name} do you mean?\n" + matching.join("\n")
      return null

    update = (env, art) ->
      tag = "tag_Name_" + env.replace /-/g, "_"
      cmd = "ansible-playbook UpdateEnvironment.yaml -l #{tag} -e \"env_name=#{env} version=#{art}\""
      r.send cmd
      exec cmd, {cwd: "/repos/tools/Ansible/Playbooks"}, (error, stdout, stderr) ->
        r.reply error if error?
        r.reply stdout if error?

    async.parallel [download("environments"), download("artifacts")], (error, result) ->
      [environments, artifacts] = result
      env = validate(environments, r.match[2], "environment", true)
      art = validate(artifacts, r.match[3], "artifact", false) if env
      update(env, art) if env && art

  robot.respond /env r(estore)? ([^ ]+)( keep)?$/i, (r) ->
    env = r.match[2]
    keep_db = "No"
    if r.match[3]?
        keep_db = "Yes"
    cmd = "sh RestoreDatabaseAndUpdateEnvironment.sh #{env} #{keep_db}"
    r.send cmd
    exec cmd, {cwd: "/repos/tools/Ansible"}, (error, stdout, stderr) ->
      r.reply error if error?
      r.reply stdout
      r.reply stderr

  robot.respond /env password(s)? ([^ ]+)\s?([^ ]+)?$/i, (r) ->
    env = r.match[2]
    request 'http://localhost:5000/passwords/' + env, (error, response, body) ->
      if error or response.statusCode == 404
        r.send 'Information about _' + env + '_ is not available.'
      else
        body = body.replace(/(\\r\\n|\\n|\\r)/gm,"")
                   .replace(/\\"/gm, '"')
        body = body.substring(1, body.length - 1)
        data = JSON.parse body

        if r.match[3]?
          tenant = r.match[3]
          if not data.hasOwnProperty(tenant)
            r.send 'Information about tenant _' + tenant + '_ is not available.'
            return
          else
            password = data[tenant]
            data = {}
            data[tenant] = password
        pwds = for tenant, pass of data
          "#{tenant} : #{pass}"
        r.send '```' + pwds.sort().join('\n') + '```'
