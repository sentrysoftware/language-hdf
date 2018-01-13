provider = require './autocomplete-provider'

module.exports =
  activate: ->
    provider.loadKeywords()

  getProvider: -> provider
