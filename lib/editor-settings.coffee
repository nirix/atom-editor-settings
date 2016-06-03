fs          = require 'fs'
path        = require 'path'
CSONParser  = require 'cson-parser'

# Config file examples:
#
# CoffeeScript grammar config example:
#   tabLength: 2
#   extensionConfig:
#     cson:
#       tabLength: 4
#
# Project / Directory config example:
#   tabLength: 2
#   grammarConfig:
#     'CoffeeScript':
#       tabLength 4
#       extensionConfig:
#         cson:
#           tabLength 8

module.exports =
  config:
    debug:
      type: 'boolean'
      default: false

  activate: ->
    console.log 'activate editor-settings'

    @watching  = []
    @configDir = atom.getConfigDirPath() + "/grammar-config"

    # Create config directory if it doesn't exist.
    if not fs.existsSync @configDir
      fs.mkdirSync @configDir

    @registerCommands()

    atom.workspace.onDidChangeActivePaneItem =>
      @reconfigureCurrentEditor()

    atom.workspace.observeTextEditors (editor) =>
      editor.observeGrammar =>
        @reconfigureCurrentEditor()

    @reconfigureCurrentEditor()

  debug: (msg) ->
    if atom.config.get('editor-settings.debug')
      console.log msg

  registerCommands: ->
    atom.commands.add 'atom-text-editor',
      'editor-settings:open-grammar-config': => @editCurrentGrammarConfig()

  # Reconfigure the current editor
  reconfigureCurrentEditor: ->
    editor = atom.workspace.getActiveTextEditor()

    @debug "reconfigure current editor"

    if editor?
      config = @loadAllConfigFiles(editor.getGrammar().name)

      editor.setTabLength   config.tabLength if config.tabLength?
      editor.setSoftTabs    config.softTabs  if config.softTabs?
      editor.setSoftWrapped config.softWrap  if config.softWrap?
      atom.config.settings.core.themes = [config.themes[0], config.themes[1]] if config.themes?

      if editor.buffer?
        buffer = editor.buffer
        buffer.setEncoding config.encoding if config.encoding

      view = atom.views.getView(editor)
      if view?
        view.style.fontFamily = config.fontFamily if config.fontFamily?
        view.style.fontSize = config.fontSize if config.fontSize?

  # Load the contents of all config files:
  #   - grammar
  #   - project
  #   - current file directory
  loadAllConfigFiles: (grammarName) ->
    editor = atom.workspace.getActiveTextEditor()

    # File extesion
    fileExtension = path.extname(editor.getPath()).substring(1)
    @debug 'current editor file extension: ' + fileExtension

    config = {}

    # Default and current Atom settings
    defaults = @merge atom.config.defaultSettings.editor,
                      atom.config.settings.editor

    config = @merge config, defaults

    # Grammar settings
    if fs.existsSync @grammarConfigPath(grammarName)
      grammarConfig = @loadConfig(@grammarConfigPath(grammarName))
      @debug 'loading grammar config: ' + grammarName
      config = @merge config, grammarConfig
    else
      @debug 'no grammar config for: ' + grammarName

    # Project settings
    if atom.project?.rootDirectories?[0]?.path?
      projectConfigPath = atom.project.rootDirectories[0].path + "/.editor-settings"

      if projectConfig = @loadConfig(projectConfigPath)
        @debug 'loading project config: ' + projectConfigPath
        config = @merge config, projectConfig

    # Directory settings
    if editor.buffer?.file?.getParent()?.path?
      directoryPath       = editor.buffer.file.getParent().path
      directoryConfigPath = directoryPath + "/.editor-settings"

      if directoryConfig = @loadConfig(directoryConfigPath)
        @debug 'loading directory config: ' + directoryConfigPath
        config = @merge config, directoryConfig

    if config.grammarConfig?[grammarName]?
      @debug 'merging grammar config: ' + grammarName
      config = @merge config, config.grammarConfig[grammarName]

    if config.extensionConfig?[fileExtension]? and fileExtension.length > 0
      @debug 'merging file extension config: ' + fileExtension
      config = @merge config, config.extensionConfig[fileExtension]

    return config

  # Merge two objects
  merge: (first, second) ->
    config = {}

    for a, b of first
      if typeof b is "object"
        config[a] = @merge {}, b
      else
        config[a] = b

    for c, d of second
      if typeof d is "object"
        config[c] = @merge {}, d
      else
        config[c] = d

    return config

  # Open current editors grammar config file
  editCurrentGrammarConfig: ->
    workspace = atom.workspace?

    return unless workspace

    editor = atom.workspace.getActiveTextEditor()

    if editor?
      grammar  = editor.getGrammar()
      filePath = @grammarConfigPath(grammar.name)

      if not fs.existsSync filePath
        fs.writeFileSync filePath, ''

      @watchFile filePath
      atom.workspace.open filePath

  # Watch file
  watchFile: (path) ->
    unless @watching[path]
      fs.watch path, =>
        @debug 'watched file updated: ' + path
        @reconfigureCurrentEditor()

      @debug 'watching: ' + path
      @watching[path] = true

  # Converts the grammar name to a file name.
  fileNameFor: (text) ->
    text.replace(/\s+/gi, '-').toLowerCase()

  # Returns full config file path for specified grammar
  grammarConfigPath: (name) ->
    fileName = @fileNameFor(name)
    return @configDir + "/" + fileName + ".cson"

  loadConfig: (path) ->
    if fs.existsSync(path)
      contents = fs.readFileSync(path)
      @watchFile path

      if contents.length > 1
        try
          return CSONParser.parse(contents)
        catch error
          console.log error
