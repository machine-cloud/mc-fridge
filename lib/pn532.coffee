events     = require("events")
serialport = require("serialport")

CARD_HEADER = new Buffer([0x01, 0x00, 0x04, 0x08, 0x04]).toString()

exports.PN532 = class PN532 extends events.EventEmitter

  constructor: (@port, options={}) ->
    @last_uid = null
    @current_uid = null
    @options =
      baud: options.baud ? 115200
      poll_rate: options.poll_rate ? 100
    @serial = new serialport.SerialPort(@port, baudRate:@options.baud)
    @serial.on "open", =>
      @serial.on "data", (data) =>
        if (idx = data.toString().indexOf(CARD_HEADER)) > -1
          @found data.slice(idx + CARD_HEADER.length, idx + CARD_HEADER.length + 3)
      setInterval (=> @poll()), @options.poll_rate

  poll: (serial) ->
    @current_uid = null unless @last_uid
    @last_uid = null
    @serial.write [0x00, 0x00, 0xff, 0x04, 0xfc, 0xd4, 0x4a, 0x01, 0x00, 0xe1, 0x00]

  found: (uid) ->
    @last_uid = uid.toString()
    return if uid.toString() is @current_uid
    @current_uid = uid.toString()
    @emit "uid", uid

exports.init = (args...) ->
  new PN532(args...)
