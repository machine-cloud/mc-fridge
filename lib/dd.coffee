coffee = require("coffee-script")

module.exports =

  arrayify: (obj) ->
    return [] unless obj?
    return obj if Array.isArray(obj)
    [obj]

  delay: (ms, cb) -> setTimeout cb, ms

  every: (ms, cb) -> setInterval cb, ms

  firstkey: (obj) -> obj[@keys(obj)[0]]

  keys: (hash) -> key for key, val of hash

  merge: coffee.helpers.merge

  now: -> (new Date()).getTime()

  reduce: (obj, start, cb) -> obj.reduce(cb, start)

  starts_with: (str, needle) -> str.indexOf(needle) is 0

  values: (hash) -> (val for key, val of hash)
