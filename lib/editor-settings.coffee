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

    # Update editor when focusing the workspace view.
    atom.workspaceView.on 'focusin', (event) =>
      view = event.targetView()

      # Check if it's an editor
      if view?.getModel? and view.getEditor?
        @setEditorConfig view

    atom.workspaceView.command 'editor-settings:open-grammar-config', => @editCurrentGrammarConfig()

  # Sets the config for the passed editor.
  setEditorConfig: (view) ->
    return unless view.getEditor?

    editor        = view.getEditor()
    grammar       = editor.getGrammar()
    grammarName   = @fileNameFor(grammar.name)
    fileExtension = path.extname(editor.getPath()).substring(1)

    # (Re)set the default editor settings, this is done in case a setting was
    # removed from the file.
    @setDefaultConfig view

    # Load the config if it hasn't already been loaded.
    @loadGrammarConfig(grammarName) unless @grammarConfig[grammarName]

    # Grammar config
    if @grammarConfig[grammarName]?
      @setConfig view, @grammarConfig[grammarName]

      # Grammar file extension config
      if @grammarConfig[grammarName].extensionConfig[fileExtension]?
        @setConfig view, @grammarConfig[grammarName].extensionConfig[fileExtension]

  # Sets the default settings for the passed editor.
  setDefaultConfig: (view) ->
    # Default settings
    @setConfig view, atom.config.defaultSettings.editor

    # User settings
    @setConfig view, atom.config.settings.editor

  # Sets the config for the passed editor from the passed config.
  setConfig: (view, config) ->
    editor = view.getEditor()

    # View related config
    view.setShowInvisibles  config.showInvisibles  if config.showInvisibles?
    view.setFontSize        config.fontSize        if config.fontSize?
    view.setFontFamily      config.fontFamily      if config.fontFamily?
    view.setShowIndentGuide config.showIndentGuide if config.showIndentGuide?

    # Editor related config
    editor.setTabLength config.tabLength if config.tabLength?
    editor.setSoftTabs  config.softTabs  if config.softTabs?
    editor.setSoftWrap  config.softWrap  if config.softWrap?

  # Loads the config for the passed grammar.
  loadGrammarConfig: (grammarName) ->
    filename = @filePathFor(grammarName)

    if fs.existsSync filename
      @watchGrammarConfig grammarName
      config = CSON.readFileSync(filename)

      if config
        config.extensionConfig = {} unless config.extensionConfig?

      @grammarConfig[grammarName] = config

  # Watches the grammar config file for changes and reloads it.
  watchGrammarConfig: (grammarName) ->
    unless @watching[grammarName]?
      file = new File(@filePathFor(grammarName))

      # Watch for file changes and reload the config and update
      # the current editor, which may not be the config file,
      # but let's just do it anyway.
      file.on 'moved removed contents-changed', =>
        @loadGrammarConfig grammarName
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
