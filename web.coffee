async      = require("async")
coffee     = require("coffee-script")
dd         = require("./lib/dd")
express    = require("express")
faye       = require("./lib/faye-redis-url")
logger     = require("logfmt").namespace(ns:"fridge.web")
mqtt       = require("./lib/mqtt-url").connect(process.env.MQTT_URL)
redis      = require("redis-url").connect(process.env.REDIS_URL)
salesforce = require("node-salesforce")
stdweb     = require("./lib/stdweb")
tempodb    = require("tempodb")

force = (cb) ->
  sf = new salesforce.Connection()
  sf.login process.env.CRM_USERNAME, process.env.CRM_PASSWORD, (err, user) ->
    cb err, sf, user

tempo = new tempodb.TempoDBClient(process.env.TEMPODB_API_KEY, process.env.TEMPODB_API_SECRET)

unit_update = (name, updates={}, cb) ->
  logger.time at:"unit_update", (logger) ->
    force (err, force) ->
      force.sobject("Unit__c").find(Name:name, "Id").limit(1).execute (err, records) ->
        cb "no such fridge" unless records[0]
        updates["Id"] = records[0]["Id"]
        force.sobject("Unit__c").update updates, (err, res) ->
          console.log "err", err
          logger.log updates
          cb err, res

decrement_stock = (name, uid, cb) ->
  logger.time at:"decrement_stock", (logger) ->
    force (err, force) ->
      force.sobject("Unit__c").find(Name:name, "Id").limit(1).execute (err, records) ->
        unit = records[0]
        force.sobject("Inventory__c").find(Name:uid, "Id").limit(1).execute (err, records) ->
          inventory = records[0]
          force.sobject("Stock__c").find(Unit__c:unit.Id, Inventory__c:inventory.Id, "Id, Quantity__c").limit(1).execute (err, records) ->
            stock = records[0]
            if stock.Quantity__c > 0
              stock.Quantity__c -= 1
              force.sobject("Stock__c").update stock, (err, res) ->
                console.log "err", err
                console.log "res", res
                cb err

app = stdweb("fridge.web")

app.use express.static("#{__dirname}/public")

socket = faye.init(process.env.REDIS_URL)
socket.attach app.server

app.get "/", (req, res) ->
  res.send "ok"

app.get "/fridge/:id/chart", (req, res) ->
  if req.headers["user-agent"].indexOf("SalesforceTouchContainer") > -1
    if req.headers["user-agent"].indexOf("iPad") > -1
      res.render "chart1ipad.jade", fridge:req.params.id
    else
      res.render "chart1.jade", fridge:req.params.id
  else
    res.render "chart.jade", fridge:req.params.id

app.get "/fridge/:id/chart.json", (req, res) ->
  redis.zrange "data:#{req.params.id}", 0, -1, (err, data) ->
    async.map data, (point, cb) ->
      cb null, JSON.parse(point)
    ,(err, points) ->
      console.log "err", err
      console.log "points", points
      res.contentType "application/json"
      res.send points

app.post "/fridge/:id/alarm", (req, res) ->
  logger.time at:"alarm", (logger) ->
    unit_update req.params.id, Door_Alarm__c:true, (err, res) ->
      res.send req.body
      logger.log req.body

app.post "/fridge/:id/door", (req, res) ->
  logger.time at:"door", (logger) ->
    updates = Door_Open__c:req.body.open
    updates.Door_Alarm__c = false if req.body.open is "false"
    unit_update req.params.id, updates, (err) ->
      res.send req.body
      logger.log req.body

app.get "/fridge/:id/update", (req, res) ->
  logger.time at:"update", (logger) ->
    mqtt.publish "/bus/#{req.params.id}", JSON.stringify(command:"update")
    res.send "ok"

app.post "/fridge/:id/report", (req, res) ->
  logger.time at:"report", (logger) ->
    unit_update req.params.id, Pressure__c:req.body.pressure, Temperature__c:req.body.temperature, (err) ->
      res.send req.body
      logger.log req.body
      now = dd.now()
      redis.multi()
        .zadd("devices", now, req.params.id)
        .zadd("data:#{req.params.id}", now, JSON.stringify(dd.merge(now:now, req.body)))
        .exec (err) ->
          logger.error err if err
      socket.getClient().publish "/fridge/#{req.params.id}/point", dd.merge(now:now, req.body)
      data = []
      data.push key:"fridge:#{req.params.id}.temperature", v:parseFloat(req.body.temperature)
      data.push key:"fridge:#{req.params.id}.pressure", v:parseFloat(req.body.pressure)
      tempo.write_bulk (new Date()), data

app.post "/fridge/:id/scan", (req, res) ->
  logger.time at:"scan", (logger) ->
    decrement_stock req.params.id, req.body.uid, (err) ->
      console.log "err", err
      res.send req.body
      logger.log req.body

app.get "/service/mqtt", (req, res) ->
  res.send process.env.MQTT_URL

app.start (port) ->
  console.log "listening on #{port}"

dd.every 3000, ->
  redis.keys "data:*", (err, devices) ->
    async.each devices, (device, cb) ->
      redis.zremrangebyscore device, 0, dd.now() - 60000, cb
    ,(err) ->
      log.error err if err
