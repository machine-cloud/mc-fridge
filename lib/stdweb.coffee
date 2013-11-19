coffee  = require("coffee-script")
express = require("express")
http    = require("http")
logfmt  = require("logfmt")

module.exports = (name) ->

  app = express()
  app.disable "x-powered-by"

  app.use logfmt.namespace(ns:name).requestLogger()
  app.use express.cookieParser()
  app.use express.bodyParser()

  app.server = http.createServer(app)

  app.start = (port, cb) ->
    if port instanceof Function
      cb = port
      port = process.env.PORT
    @server.listen port, ->
      cb port

  app
