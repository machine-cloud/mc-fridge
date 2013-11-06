async = require("async")
i2c   = require("i2c")

exports.PN532 = class PN532

  constructor: ->
    @wire = new i2c(0x24, device:"/dev/i2c-1")
    @wire.scan (err, data) ->
      console.log "err", err
      console.log "data", data

  temperature: (cb) ->
    cb null

  read: (cb) ->
    @write_bytes [0x00, 0x00, 0xff, 0x04, 0xfc, 0xd4, 0x4a, 0x01, 0x00, 0xe1, 0x00], (err, d2) =>
      return cb(err) if err
      @read_bytes 6, (err, data) ->
        console.log "err", err
        console.log "data", data

  write_bytes: (bytes, cb) ->
    async.eachSeries bytes,
      (byte, cb) =>
        @wire.writeByte byte, cb
      (err) ->
        cb err

  read_bytes: (count) ->
    async.mapSeries [0..(count-1)],
      (i, cb) =>
        @wire.readByte cb
      (err, data) ->
        console.log "rerr", err
        console.log "rdata", data

exports.init = (args...) ->
  new PN532(args...)
