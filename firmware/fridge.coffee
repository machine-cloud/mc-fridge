async   = require("async")
bmp085  = require("bmp085")
dd      = require("./lib/dd")
gpio    = require("./lib/gpio").init(inputs:7, outputs:[18, 22])
logger  = require("logfmt").namespace(ns:"fridge.firmware")
pn532   = require("./lib/pn532").init("/dev/ttyAMA0")
request = require("request")
spawn   = require("child_process").spawn

DOOR_OPEN_ALARM = 15

DANCE_INTERVAL  = 200
DANCE_TIMES     = 5
REPORT_INTERVAL = 3

DOOR_PIN      = 7
RED_LED_PIN   = 18
GREEN_LED_PIN = 22

dance_lights = (times, interval, cb) ->
  async.eachSeries [1..times],
    (i, cb) ->
      gpio.set RED_LED_PIN,   true
      gpio.set GREEN_LED_PIN, false
      dd.delay interval, ->
        gpio.set RED_LED_PIN,   false
        gpio.set GREEN_LED_PIN, true
        dd.delay interval, cb
    cb

flash_light = (pin, times, interval, cb) ->
  async.eachSeries [1..times],
    (i, cb) ->
      gpio.set pin, true
      dd.delay interval, ->
        gpio.set pin, false
        dd.delay interval, cb
    cb

dance_lights DANCE_TIMES, DANCE_INTERVAL, ->
  gpio.set RED_LED_PIN,   false
  gpio.set GREEN_LED_PIN, false

  request.get "#{process.env.HOST}/service/mqtt", (err, res) ->
    mqtt = require("./lib/mqtt-url").connect(res.body)
    mqtt.on "connect", ->
      mqtt.subscribe "/bus/#{process.env.ID}"
    mqtt.on "message", (channel, data) ->
      message = JSON.parse(data)
      switch message.command
        when "update"
          console.log "updating"
          flash_light GREEN_LED_PIN, 5, 300, ->
            git = spawn "git", ["pull"], cwd:"/home/pi/mc-fridge"
            git.stdout.on "data", (data) -> console.log "stdout", data.toString()
            git.stderr.on "data", (data) -> console.log "stderr", data.toString()
            git.on "close", -> process.exit()

  pn532.on "uid", (uid) ->
    uid = uid.toString("hex")
    logger.time at:"scan", (logger) ->
      gpio.set GREEN_LED_PIN, true
      dd.delay 200, ->
        gpio.set GREEN_LED_PIN, false
      logger.log uid:uid
      request.post "#{process.env.HOST}/fridge/#{process.env.ID}/scan", form:{uid:uid}, (err, res) ->
        if err
          logger.log post:"error", error:err
        else
          logger.log post:"success"

  alarm = null
  alarm_flasher = null
  alarm_on = false
  open = false

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
        if value is 1
          alarm = dd.delay DOOR_OPEN_ALARM * 1000, ->
            alarm_flasher = dd.every 300, ->
              alarm_on = !alarm_on
              gpio.set RED_LED_PIN, alarm_on
            request.post "#{process.env.HOST}/fridge/#{process.env.ID}/alarm", form:{seconds:DOOR_OPEN_ALARM}, (err, res) ->
              if err
                logger.log alarm:"error", error:err
              else
                logger.log alarm:"success"
        else
          if alarm
            clearTimeout alarm
            alarm = null
          if alarm_flasher
            clearInterval alarm_flasher
            alarm_flasher = null
            gpio.set RED_LED_PIN, false

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
