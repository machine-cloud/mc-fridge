bmp085 = require("bmp085")
dd     = require("./lib/dd")
gpio   = require("./lib/gpio").init([7])
pn532  = require("./lib/pn532").init("/dev/ttyAMA0")

red = 18
green = 22

gpio.set red, false
gpio.set green, false

pn532.on "uid", (uid) ->
  console.log "uid", uid
  gpio.set green, true
  dd.delay 200, ->
    gpio.set green, false, ->
      gpio.set green, false

gpio.on "change", (pin, value) ->
  console.log "change", pin, value
  gpio.set red, value if pin is 7

sensor = new bmp085()

dd.every 500, ->
  sensor.read (data) ->
    console.log "data", data
