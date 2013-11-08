dd     = require("./dd")
events = require("events")
gpio   = require("pi-gpio")

exports.GPIO = class GPIO extends events.EventEmitter

  constructor: (options={}) ->
    @state = {}
    @options =
      inputs: dd.arrayify(options.inputs ? [])
      outputs: dd.arrayify(options.outputs ? [])
      poll_rate: options.poll_rate ? 300
    for input in @options.inputs
      gpio.close input
      gpio.open input, "input"
    for output in @options.outputs
      gpio.close output
      gpio.open output, "output"
    setInterval (=> @poll()), @options.poll_rate

  poll: ->
    for pin in @options.inputs
      gpio.read pin, (err, value) =>
        @value pin, value unless err

  set: (pin, value, cb) ->
    gpio.write pin, value, ->
      gpio.write pin, value, cb

  value: (pin, value) ->
    @emit "change", pin, value unless @state[pin] is value
    @state[pin] = value

exports.init = (args...) ->
  new GPIO(args...)
