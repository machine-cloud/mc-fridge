bmp085  = require("bmp085")
dd      = require("./lib/dd")
gpio    = require("./lib/gpio").init([7])
logger  = require("logfmt").namespace(ns:"fridge.firmware")
pn532   = require("./lib/pn532").init("/dev/ttyAMA0")
request = require("request")

DOOR_OPEN_ALARM = 3
REPORT_INTERVAL = 3

DOOR_PIN      = 7
RED_LED_PIN   = 18
GREEN_LED_PIN = 22

gpio.set RED_LED_PIN,   false
gpio.set GREEN_LED_PIN, false

pn532.on "uid", (uid) ->
  uid = uid.toString("hex")
  logger.time at:"scan", (logger) ->
    gpio.set GREEN_LED_PIN, true
    dd.delay 200, ->
      gpio.set GREEN_LED_PIN, false, ->
        gpio.set GREEN_LED_PIN, false
    logger.log uid:uid
    request.post "#{process.env.HOST}/fridge/#{process.env.ID}/scan", form:{uid:uid}, (err, res) ->
      if err
        logger.log post:"error", error:err
      else
        logger.log post:"success"

gpio.on "change", (pin, value) ->
  if pin is DOOR_PIN
    logger.time at:"door", (logger) ->
      gpio.set RED_LED_PIN, value
      open = (value is 1)
      logger.log open:open
      request.post "#{process.env.HOST}/fridge/#{process.env.ID}/door", form:{open:open}, (err, res) ->
        if err
          logger.log post:"error", error:err
        else
          logger.log post:"success"

sensor = new bmp085()

dd.every REPORT_INTERVAL * 1000, ->
  logger.time at:"report", (logger) ->
    sensor.read (data) ->
      logger.log data
      request.post "#{process.env.HOST}/fridge/#{process.env.ID}/report", form:data, (err, res) ->
        if err
          logger.log post:"error", error:err
        else
          logger.log post:"success"