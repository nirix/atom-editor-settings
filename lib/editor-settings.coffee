{$}    = require 'atom'
fs     = require 'fs'
CSON   = require 'season'
{File} = require 'pathwatcher'
path   = require 'path'

module.exports =
  grammarConfig: {}
  watching: []

  activate: ->
    @configDir = atom.getConfigDirPath() + "/grammar-config/"
    @baseConfig = atom.config.configFilePath

    # Create config directory if it doesn't exist.
    if not fs.existsSync @configDir
      fs.mkdirSync @configDir

    atom.workspaceView.on "pane-container:active-pane-item-changed", => @updateCurrentEditor()
    atom.workspaceView.on "editor:grammar-changed", => @updateCurrentEditor()

    atom.workspaceView.command 'editor-settings:open-grammar-config', => @editCurrentGrammarConfig()

  # Sets the config for the passed editor.
  setEditorConfig: (view) ->
    return unless view and view.getEditor?

    grammarName = @fileNameFor(view.getEditor().getGrammar().name)

    if @grammarConfig[grammarName]
      @configureEditor(view, @grammarConfig[grammarName])
    else
      @loadGrammarConfig grammarName, =>
        @configureEditor(view, @grammarConfig[grammarName])

  # Configures the editor with the passed configuration.
  configureEditor: (view, config) ->
    editor        = view.getEditor()
    grammar       = editor.getGrammar()
    grammarName   = @fileNameFor(grammar.name)
    fileExtension = path.extname(editor.getPath()).substring(1)

    # Get defaults
    config = @mergeConfig atom.config.defaultSettings.editor,
                          atom.config.settings.editor

    # Grammar config
    if @grammarConfig[grammarName]?
      config = @mergeConfig config, @grammarConfig[grammarName]

      # Extension specific
      if config.extensionConfig[fileExtension]?
        config = @mergeConfig config, config.extensionConfig[fileExtension]

    # Set the config
    @setConfig view, config

  # Sets the config for the passed editor from the passed config.
  setConfig: (view, config) ->
    editor = view.getEditor()

    # View related config
    view.setInvisibles      config.invisibles      if config.invisibles?
    view.setShowInvisibles  config.showInvisibles  if config.showInvisibles?
    view.setFontSize        config.fontSize        if config.fontSize?
    view.setFontFamily      config.fontFamily      if config.fontFamily?
    view.setShowIndentGuide config.showIndentGuide if config.showIndentGuide?
    view.setLineHeight      config.lineHeight      if config.lineHeight?

    # Editor related config
    editor.setTabLength config.tabLength if config.tabLength?
    editor.setSoftTabs  config.softTabs  if config.softTabs?
    editor.setSoftWrap  config.softWrap  if config.softWrap?

  # Merge two configurations together.
  mergeConfig: (first, second) ->
    config = first

    for k, v of second
      config[k] = v

    return config

  # Loads the config for the passed grammar.
  loadGrammarConfig: (grammarName, callback) ->
    filename = @filePathFor(grammarName)

    fs.exists filename, (exists) =>
      if exists
        @watchGrammarConfig grammarName
        CSON.readFile filename, (error, config = {}) =>
          if config
            config.extensionConfig = {} unless config.extensionConfig?
            @grammarConfig[grammarName] = config
            callback()

  # Watches the grammar config file for changes and reloads it.
  watchGrammarConfig: (grammarName) ->
    unless @watching[grammarName]?
      file = new File(@filePathFor(grammarName))

      # Watch for file changes and reload the config and update
      # the current editor, which may not be the config file,
      # but let's just do it anyway.
      file.on 'moved removed contents-changed', =>
        @loadGrammarConfig grammarName, =>
          @updateCurrentEditor()

      @watching[grammarName] = file

  # Updates the currently active editor config.
  updateCurrentEditor: ->
    view = atom.workspaceView.getActiveView()
    @setEditorConfig view

  # Converts the grammar name to a file name.
  fileNameFor: (grammarName) ->
    grammarName.replace(/\s+/gi, '-').toLowerCase()

  # Returns the path for the grammar config file.
  filePathFor: (grammarName) ->
    @configDir + grammarName + ".cson"

  editCurrentGrammarConfig: ->
    grammar     = atom.workspace.getActiveEditor()?.getGrammar()
    grammarName = @fileNameFor(grammar.name)
    filepath    = @filePathFor(grammarName)

    if not fs.existsSync filepath
      fs.writeFileSync filepath, ''
      @watchGrammarConfig grammarName

    atom.workspace.open filepath
