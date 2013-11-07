async   = require("async")
coffee  = require("coffee-script")
dd      = require("./lib/dd")
express = require("express")
logger  = require("logfmt").namespace(ns:"fridge.web")
stdweb  = require("./lib/stdweb")

app = stdweb("fridge.web")

app.get "/", (req, res) ->
  res.send "ok"

app.post "/fridge/:id/door", (req, res) ->
  logger.time at:"door", (logger) ->
    res.send req.body
    logger.log req.body

app.post "/fridge/:id/report", (req, res) ->
  logger.time at:"report", (logger) ->
    res.send req.body
    logger.log req.body

app.post "/fridge/:id/scan", (req, res) ->
  logger.time at:"scan", (logger) ->
    res.send req.body
    logger.log req.body

app.start (port) ->
  console.log "listening on #{port}"
