bmp085 = require("bmp085")
dd     = require("./lib/dd")
gpio   = require("./lib/gpio").init([7])
pn532  = require("./lib/pn532").init("/dev/ttyAMA0")

pn532.on "uid", (uid) ->
  console.log "uid", uid

gpio.on "change", (pin, value) ->
  console.log "change", pin, value

sensor = new bmp085()

dd.every 500, ->
  sensor.read (data) ->
    console.log "data", data
