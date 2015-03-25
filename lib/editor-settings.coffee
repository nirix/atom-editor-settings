{$}    = require 'atom'
fs     = require 'fs'
CSON   = require 'season'
{File} = require 'pathwatcher'
path   = require 'path'
CSONParser = require 'cson-parser'

module.exports =
  grammarConfig: {}
  watching: []

  activate: ->
    @configDir = atom.getConfigDirPath() + "/grammar-config/"
    @baseConfig = atom.config.configFilePath

    # Create config directory if it doesn't exist.
    if not fs.existsSync @configDir
      fs.mkdirSync @configDir

    editor = atom.workspace.getActiveTextEditor()

    atom.workspace.onDidChangeActivePaneItem => @updateCurrentEditor()

    atom.commands.add 'atom-text-editor',
      'editor-settings:open-grammar-config': => @editCurrentGrammarConfig()

    @updateCurrentEditor()

    # atom.workspace.command 'editor-settings:open-grammar-config', => @editCurrentGrammarConfig()

  # Sets the config for the passed editor.
  setEditorConfig: (editor) ->
    return unless editor

    grammarName = @fileNameFor(editor.getGrammar().name)

    if @grammarConfig[grammarName]
      @configureEditor(editor, @grammarConfig[grammarName])
    else
      @loadGrammarConfig grammarName, =>
        @configureEditor(editor, @grammarConfig[grammarName])

  # Load directory config
  loadDirectoryConfig: (path) ->
    filePath = path + "/.editor-settings"
    if fs.existsSync(filePath)
      contents = fs.readFileSync(filePath)

      if contents.length > 1
        CSONParser.parse(contents)

  # Loads the project specific configuration
  loadProjectConfig: ->
    @loadDirectoryConfig(atom.project.rootDirectory.path)

  # Merges together the grammar and file extension specific settings from an
  # `.editor-settings` file.
  mergeDirectoryConfig: (directoryConfig, grammarName, fileExtension) ->
    config = directoryConfig

    if directoryConfig?[grammarName]?
      grammarConfig = directoryConfig[grammarName]
      config = @mergeConfig(config, grammarConfig)

      if grammarConfig.extensionConfig?[fileExtension]?
        config = @mergeConfig(config, grammarConfig.extensionConfig[fileExtension])

    return config

  # Configures the editor with the passed configuration.
  configureEditor: (editor, config) ->
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

    # Project config
    if atom.project?.path?
      projectConfig = @loadProjectConfig()

      if projectConfig?
        projectConfig = @mergeDirectoryConfig(projectConfig, grammarName, fileExtension)
        config = @mergeConfig(config, projectConfig)

    # Load directory config
    if editor?.buffer?.file?.getParent()?.path?
      directoryPath = editor.buffer.file.getParent().path
      directoryConfig = @loadDirectoryConfig(directoryPath)

      if directoryConfig?
        directoryConfig = @mergeDirectoryConfig(directoryConfig, grammarName, fileExtension)
        config = @mergeConfig(config, directoryConfig)

    # Set the config
    @setConfig editor, config

  # Sets the config for the passed editor from the passed config.
  setConfig: (editor, config) ->
    # View related config
    # view.setFontSize        config.fontSize        if config.fontSize?
    # view.setFontFamily      config.fontFamily      if config.fontFamily?
    # view.setShowIndentGuide config.showIndentGuide if config.showIndentGuide?
    # view.setLineHeight      config.lineHeight      if config.lineHeight?

    # Editor related config
    editor.setTabLength config.tabLength if config.tabLength?
    editor.setSoftTabs  config.softTabs  if config.softTabs?
    editor.setSoftWrap  config.softWrap  if config.softWrap?
    editor.setEncoding  config.encoding  if config.encoding?

    # Invisible characters
    if not config.showInvisibles
      editor.displayBuffer.setInvisibles false
    else
      editor.displayBuffer.setInvisibles config.invisibles

  # Merge two configurations together.
  mergeConfig: (first, second) ->
    config = {}

    for a, b of first
      if typeof b == 'object'
        config[a] = @mergeConfig {}, b
      else
        config[a] = b

    for c, d of second
      if typeof d == 'object'
        config[c] = @mergeConfig {}, d
      else
        config[c] = d

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
    editor = atom.workspace.getActiveTextEditor()
    @setEditorConfig editor

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
