async      = require("async")
coffee     = require("coffee-script")
dd         = require("./lib/dd")
express    = require("express")
logger     = require("logfmt").namespace(ns:"fridge.web")
salesforce = require("node-salesforce")
stdweb     = require("./lib/stdweb")

force = (cb) ->
  sf = new salesforce.Connection()
  sf.login process.env.CRM_USERNAME, process.env.CRM_PASSWORD, (err, user) ->
    cb err, sf, user

unit_update = (name, updates={}, cb) ->
  logger.time at:"unit_update", (logger) ->
    force (err, force) ->
      force.sobject("Unit__c").find(Name:name, "Id").limit(1).execute (err, records) ->
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

app.get "/", (req, res) ->
  res.send "ok"

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

app.post "/fridge/:id/report", (req, res) ->
  logger.time at:"report", (logger) ->
    unit_update req.params.id, Pressure__c:req.body.pressure, Temperature__c:req.body.temperature, (err) ->
      res.send req.body
      logger.log req.body

app.post "/fridge/:id/scan", (req, res) ->
  logger.time at:"scan", (logger) ->
    decrement_stock req.params.id, req.body.uid, (err) ->
      console.log "err", err
      res.send req.body
      logger.log req.body

app.start (port) ->
  console.log "listening on #{port}"
