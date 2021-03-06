# Notifies about Jenkins builds via Jenkins Notification Plugin
#
# Configuration:
#
#   Just put this url
#   <HUBOT_URL>:<PORT>/<HUBOT_NAME>/jenkins?room=<room> to your
#   Jenkins Notification config. See here:
#   https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin
#
# Commands:
#   None
#
# Environment:
#   HUBOT_JENKINS_COLOR_ABORTED: color for aborted builds
#   HUBOT_JENKINS_COLOR_FAILURE: color for failed builds
#   HUBOT_JENKINS_COLOR_FIXED: color for fixed builds
#   HUBOT_JENKINS_COLOR_STILL_FAILING: color for still failing builds
#   HUBOT_JENKINS_COLOR_SUCCESS: color for success builds
#   HUBOT_JENKINS_COLOR_DEFAULT: default color for builds
#
# URLS:
#   POST /<robot-name>/jenkins?room=<room>
#
# Authors:
#   inkel

HUBOT_JENKINS_COLOR_ABORTED       = process.env.HUBOT_JENKINS_COLOR_ABORTED       || "warning"
HUBOT_JENKINS_COLOR_FAILURE       = process.env.HUBOT_JENKINS_COLOR_FAILURE       || "danger"
HUBOT_JENKINS_COLOR_FIXED         = process.env.HUBOT_JENKINS_COLOR_FIXED         || "#d5f5dc"
HUBOT_JENKINS_COLOR_STILL_FAILING = process.env.HUBOT_JENKINS_COLOR_STILL_FAILING || "danger"
HUBOT_JENKINS_COLOR_SUCCESS       = process.env.HUBOT_JENKINS_COLOR_SUCCESS       || "good"
HUBOT_JENKINS_COLOR_DEFAULT       = process.env.HUBOT_JENKINS_COLOR_DEFAULT       || "#ffe094"
HUBOT_JENKINS_BOT_ICON            = process.env.HUBOT_JENKINS_BOT_ICON            || "http://jenkins-ci.org/sites/default/files/images/headshot.png"
HUBOT_JENKINS_BOT_NAME            = process.env.HUBOT_JENKINS_BOT_NAME            || "Jenkins"

module.exports = (robot) ->
  robot.router.post "/#{robot.name}/jenkins", (req, res) ->
    room = req.query.room

    unless room?
      res.status(400).send("Bad Request").end()
      return

    if req.query.debug
      console.log req.body

    data = req.body

    res.status(202).end()

    return if data.build.phase == "COMPLETED"

    payload =
      message:
        room: "##{room}"
      content:
        fields: []

    payload.content.fields.push
      title: "Phase"
      value: data.build.phase
      short: true

    if data.build.duration
      payload.content.fields.push
        title: "Duration"
        value: data.build.duration
        short: true

    switch data.build.phase
      when "FINALIZED"
        status = "#{data.build.status}"


        if data.build.scm?.commit
          payload.content.fields.push
            title: "Commit SHA1"
            value: data.build.scm.commit
            short: true
              
        if data.build.scm?.branch
          payload.content.fields.push
            title: "Branch"
            value: data.build.scm.branch
            short: true


        color = switch data.build.status
          when "ABORTED"       then HUBOT_JENKINS_COLOR_ABORTED
          when "FAILURE"       then HUBOT_JENKINS_COLOR_FAILURE
          when "FIXED"         then HUBOT_JENKINS_COLOR_FIXED
          when "STILL FAILING" then HUBOT_JENKINS_COLOR_STILL_FAILING
          when "SUCCESS"       then HUBOT_JENKINS_COLOR_SUCCESS
          else                      HUBOT_JENKINS_COLOR_DEFAULT

      when "STARTED"
        status = data.build.phase
        color = "#e9f1ea"

        params = data.build.parameters

        if params?.ghprbPullId
          payload.content.fields.push
            title: "Source branch"
            value: params.ghprbSourceBranch
            short: true
          payload.content.fields.push
            title: "Target branch"
            value: params.ghprbTargetBranch
            short: true
          payload.content.fields.push
            title: "Pull request"
            value: "#{params.ghprbPullId}: #{params.ghprbPullTitle}"
            short: true
          payload.content.fields.push
            title: "URL"
            value: params.ghprbPullLink
            short: true
        else
          if data.build.scm?.commit
            payload.content.fields.push
              title: "Commit SHA1"
              value: data.build.scm.commit
              short: true
          if data.build.scm?.branch
            payload.content.fields.push
              title: "Branch"
              value: data.build.scm.branch
              short: true

    payload.content.color     = color
    payload.content.title      = "<#{data.build.full_url}| ##{data.build.number}  #{data.name} >  #{status}"
    payload.content.fallback  = "Jenkins #{data.name} #{data.build.phase} #{status} #{data.build.full_url}"
    payload.username          = HUBOT_JENKINS_BOT_NAME
    payload.icon_url          = HUBOT_JENKINS_BOT_ICON

    if req.query.debug
      console.log payload

    robot.emit "slack.attachment", payload
