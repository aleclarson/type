
NamedFunction = require "NamedFunction"
emptyFunction = require "emptyFunction"
mergeDefaults = require "mergeDefaults"
isConstructor = require "isConstructor"
assertTypes = require "assertTypes"
assertType = require "assertType"
sliceArray = require "sliceArray"
Property = require "Property"
Builder = require "Builder"
setKind = require "setKind"
setType = require "setType"
hasKeys = require "hasKeys"
combine = require "combine"
isType = require "isType"
define = require "define"
Shape = require "Shape"
sync = require "sync"
bind = require "bind"
has = require "has"

TypeBuilder = NamedFunction "TypeBuilder", (name, func) ->
  self = Builder name, func
  setType self, TypeBuilder
  TypeBuilder.props.define self, arguments
  return self

module.exports = setKind TypeBuilder, Builder

TypeBuilder.props = Property.Map

  _argPhases: -> []

  _argTypes: null

  _optionTypes: null

  _getCacheID: null

  _getExisting: null

define TypeBuilder.prototype,

  defineArgs: (args) ->
    assertType args, Object

    if @_argTypes
      throw Error "'defineArgs' must only be called once!"

    argNames = []
    argTypes = {}
    argDefaults = {}
    requiredTypes = {}

    sync.each args, (arg, name) ->
      argNames.push name
      if not isType arg, Object
        argTypes[name] = arg
        return
      if has arg, "default"
        argDefaults[name] = arg.default
      if argType = arg.type
        if isType argType, Object
          argType = Shape argType
        if arg.required
          requiredTypes[name] = yes
        argTypes[name] = argType

    validateArgs = (args) ->
      for name, index in argNames
        arg = args[index]
        if arg is undefined
          if argDefaults[name] isnt undefined
            args[index] = arg = argDefaults[name]
          else if not requiredTypes[name]
            continue
        if isDev
          argType = argTypes[name]
          argType and assertType arg, argType, "args[#{index}]"
      return args

    @_argTypes = argTypes
    @_argPhases.push validateArgs
    @didBuild (type) ->
      if hasKeys argTypes
        type.argTypes = argTypes
        overrideObjectToString argTypes, gatherTypeNames
      if hasKeys argDefaults
        type.argDefaults = argDefaults
    return

  initArgs: (func) ->
    assertType func, Function

    initArgs = (args) ->
      func.call null, args
      return args

    isDev and initArgs = bind.toString func, initArgs
    @_argPhases.push initArgs
    return

  replaceArgs: (func) ->
    assertType func, Function

    replaceArgs = (args) ->
      args = func.call null, args
      return args if args and args.length
      throw TypeError "Must return an array-like object!"

    isDev and replaceArgs = bind.toString func, replaceArgs
    @_argPhases.push replaceArgs
    return

  defineOptions: (options) ->
    assertType options, Object

    if @_optionTypes
      throw Error "'defineOptions' must only be called once!"

    optionNames = []
    optionTypes = {}
    optionDefaults = {}
    requiredTypes = {}

    sync.each options, (option, name) ->
      optionNames.push name
      if not isType option, Object
        optionTypes[name] = option
        return
      if has option, "default"
        optionDefaults[name] = option.default
      if optionType = option.type
        if isType optionType, Object
          optionType = Shape optionType
        if option.required
          requiredTypes[name] = yes
        optionTypes[name] = optionType

    validateOptions = (args) ->
      options = args[0]
      options or args[0] = options = {}
      assertType options, Object, "options"
      for name in optionNames
        option = options[name]
        if option is undefined
          if optionDefaults[name] isnt undefined
            options[name] = option = optionDefaults[name]
          else if not requiredTypes[name]
            continue
        if isDev
          optionType = optionTypes[name]
          optionType and assertType option, optionType, "options." + name
      return args

    @_optionTypes = optionTypes
    @_argPhases.push validateOptions
    @didBuild (type) ->
      if hasKeys optionTypes
        type.optionTypes = optionTypes
        overrideObjectToString optionTypes, gatherTypeNames
      if hasKeys optionDefaults
        type.optionDefaults = optionDefaults
    return

  returnCached: (func) ->
    assertType func, Function
    @_getCacheID = func
    @didBuild (type) ->
      type.cache = Object.create null
      return
    return

  returnExisting: (func) ->
    assertType func, Function
    @_getExisting = func
    return

define TypeBuilder.prototype,

  __buildArgCreator: ->

    phases = @_argPhases

    if phases.length is 0
      return emptyFunction.thatReturnsArgument

    return (args) ->
      args = sliceArray args
      for phase in phases
        args = phase.call null, args
      return args

  __buildInstanceCreator: ->

    createInstance = Builder::__buildInstanceCreator.call this

    getCacheID = @_getCacheID
    if getCacheID
      return (type, args) ->
        id = getCacheID.apply null, args
        return createInstance type, args if id is undefined
        instance = type.cache[id]
        return instance if instance
        return type.cache[id] = createInstance type, args

    getExisting = @_getExisting
    if getExisting
      return (type, args) ->
        instance = getExisting.apply null, args
        return instance if instance
        return createInstance type, args

    return createInstance

#
# Helpers
#

overrideObjectToString = (obj, transform) ->
  Object.defineProperty obj, "toString",
    value: -> log._format transform(obj), { unlimited: yes, colors: no }

gatherTypeNames = (type) ->

  if isType type, Object
    return sync.map type, gatherTypeNames

  if type.getName
    return type.getName()

  return type.name
