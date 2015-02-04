# #Play Plugin

# This is an plugin to play audio files in pimatic

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  fs = require 'fs'
  path = require 'path'
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  util = env.require 'util'
  M = env.matcher
  # Require the [play](https://github.com/Marak/play.js) library
  Play = require('play').Play
  Promise.promisifyAll(Play.prototype)

  playService = null

  # ###Play class
  class PlayPlugin extends env.plugins.Plugin

    # ####init()
    init: (app, @framework, config) =>
      
      player = config.player
      env.logger.debug "play: player=#{player}"
      playService = new Play()
      playService.usePlayer(player) if player?
      
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

      # get path of file to be played
      fullpath = Promise.all( [ @framework.variableManager.evaluateStringExpression(@fileTokens) ])
        # get full path
        .then( ([file]) => return path.resolve @framework.maindir, '../..', file)
      
      fullpath.then( (file) => 
        # check if file exists 
        fs.statAsync(file))
        .then( (filestats) => 
          if not filestats.isFile()
            throw new Error("path is not a file (but e.g. a folder"))
        # play file
        .then( => 
          fp=fullpath.value() 
          if simulate
             env.logger.info __("would play file \"%s\"", fp)
             # just return a promise fulfilled with a description about what we would do.
             return __("would play file \"%s\"", fp)
          else
            env.logger.info __("played \"%s\"", fp)
            return playService.soundAsync(fp).then( => return __("played \"%s\"", fp)))
        # log error if file does not exist
        .catch( =>
          fp=fullpath.value() 
          env.logger.error __("could not play file: \"%s\"", fp)
          return __("could not play file: \"%s\"", fp))
        

  module.exports.PlayActionHandler = PlayActionHandler

  # and return it to the framework.
  return plugin   
