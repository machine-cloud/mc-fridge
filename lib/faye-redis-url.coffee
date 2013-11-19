faye  = require("faye")
redis = require("faye-redis")
url   = require("url")

module.exports.init = (redis_url, options={}) ->
  options.mount     ?= "/faye"
  options.namespace ?= "faye"
  options.timeout   ?= 25
  parsed = url.parse(redis_url)
  socket = new faye.NodeAdapter
    mount: options.mount
    timeout: options.timeout
    engine:
      type: redis
      host: parsed.hostname
      port: parsed.port
      password: (parsed.auth or "").split(":")[1]
      database: (parsed.path or "/0").slice(1)
      namespace: options.namespace
  socket
