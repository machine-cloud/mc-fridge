coffee  = require("coffee-script")
express = require("express")
logfmt  = require("logfmt")

module.exports = (name) ->

  app = express()
  app.disable "x-powered-by"

  app.use logfmt.namespace(ns:name).requestLogger()
  app.use express.cookieParser()
  app.use express.bodyParser()

  app.start = (port, cb) ->
    if port instanceof Function
      cb = port
      port = process.env.PORT
    @listen port, ->
      cb port

  app
