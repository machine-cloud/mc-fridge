events = require("events")
gpio   = require("pi-gpio")

exports.GPIO = class GPIO extends events.EventEmitter

  constructor: (@pins, options={}) ->
    @state = {}
    @options =
      poll_rate: options.poll_rate ? 300
    setInterval (=> @poll()), @options.poll_rate

  poll: ->
    for pin in @pins
      gpio.open pin, "input", (err) =>
        gpio.read pin, (err, value) =>
          @value pin, value unless err
          gpio.close pin

  set: (pin, value, cb) ->
    gpio.open pin, "output", (err) =>
      gpio.write pin, value, ->
        gpio.close pin, ->
          cb() if cb

  value: (pin, value) ->
    @emit "change", pin, value unless @state[pin] is value
    @state[pin] = value

exports.init = (args...) ->
  new GPIO(args...)
