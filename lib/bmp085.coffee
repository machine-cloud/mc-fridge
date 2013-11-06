i2c = require("i2c")

exports.BMP085 = class BMP085

  constructor: ->
    @wire = new i2c(0x77, device:"/dev/i2c-1")

  temperature: (cb) ->
    cb null

  read: (address, cb) ->
    @wire.readBytes address, 2, (err, data) ->
      console.log "err", err
      console.log "data", data

exports.init = (args...) ->
  new BMP085(args...)
