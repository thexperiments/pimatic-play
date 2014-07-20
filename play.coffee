# #Play Plugin

# This is an plugin to play audio files in pimatic

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  util = env.require 'util'
  M = env.matcher
  # Require the [play](https://github.com/Marak/play.js) library
  Play = require 'play'
  Promise.promisifyAll(Play.Play())

  playService = null

  # ###Play class
  class PlayPlugin extends env.plugins.Plugin

    # ####init()
    init: (app, @framework, config) =>
      
      player = config.player
      env.logger.debug "play: player= #{player}"

      playService = Play.Play()

      #Play.setPlayer(player)
      
      @framework.ruleManager.addActionProvider(new PlayActionProvider @framework, config)
  
  # Create a instance of my plugin
  plugin = new PlayPlugin()

  class PlayActionProvider extends env.actions.ActionProvider
  
    constructor: (@framework, @config) ->
      return

    parseAction: (input, context) =>


      # Helper to convert 'some text' to [ '"some text"' ]
      strToTokens = (str) => ["\"#{str}\""]

      fileTokens = strToTokens ""

      setFile = (m, tokens) => fileTokens = tokens

      m = M(input, context)
        .match(['play ']).matchStringWithVars(setFile)

      if m.hadMatch()
        match = m.getFullMatch()

        assert Array.isArray(fileTokens)

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new PlayActionHandler(
            @framework, fileTokens
          )
        }
            

  class PlayActionHandler extends env.actions.ActionHandler 

    constructor: (@framework, @fileTokens) ->

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@fileTokens)
      ]).then( ([file]) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would play file \"%s\"", file)
        else
          promisedPlay = Promise.promisify(playService.sound, playService)
          return promisedPlay file
      )

  module.exports.PlayActionHandler = PlayActionHandler

  # and return it to the framework.
  return plugin   
