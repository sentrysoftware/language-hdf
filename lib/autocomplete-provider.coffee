fs = require 'fs'
path = require 'path'

basicKeywordPattern = /(^\s*|=\s*%)((([a-z]+)\.)*)([a-z]*)\s*$/i

module.exports =
  selector: '.source.hdf'
  disableForSelector: '.source.hdf .comment, .source.hdf .string, .source.hdf .constant, .source.hdf .meta.function'
  filterSuggestions: false
  inclusionPriority: 1
  suggestionPriority: 2

  getSuggestions: (request) ->
    completions = null
#    scopes = request.scopeDescriptor.getScopesArray()

    editor = request.editor
    bufferPosition = request.bufferPosition
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

    # Check for basic keywords
    lineElements = basicKeywordPattern.exec(line)
    if lineElements?
      radix = lineElements[2]
      prefix = lineElements[5]

      completions = []
      for keywordEntry in @basicKeywords when radix.toLowerCase() == keywordEntry.radix and keywordEntry.lowerCaseKeyword.startsWith(prefix.toLowerCase())
        completions.push({ type: "keyword", text: keywordEntry.keyword })
      return completions

    # Check for single-keywords (after Detection.Criteria(x), Source(x), or Compute(x))
    for {pattern, keywordArray, keywordType } in @otherSimpleKeywords
      lineElements = pattern.exec(line)
      if lineElements?
        prefix = lineElements?[1]
        completions = []
        for keyword in keywordArray when keyword.toLowerCase().startsWith(prefix.toLowerCase())
          completions.push({ type: keywordType, text: keyword })
        return completions

    completions

  # onDidInsertSuggestion: ({editor, suggestion}) ->
  #   setTimeout(@triggerAutocomplete.bind(this, editor), 1) if suggestion.type is 'property'

  triggerAutocomplete: (editor) ->
    atom.commands.dispatch(atom.views.getView(editor), 'autocomplete-plus:activate', {activatedManually: false})

  ###
  # loadKeywords:
  #
  # Read the keyword files and create the (efficient) structures to will help us
  # identify the possible keywords that follows what the brave developer is typing
  ###
  loadKeywords: ->

    # Basic Keywords (for non-array hdfs elements)
    @basicKeywords = []
    content = fs.readFileSync path.resolve(__dirname, '..', 'completions-basic.txt')
    for keyword in content.toString().replace('\r', '').split('\n') when keyword?.trim().length > 0
        keywordElements = basicKeywordPattern.exec(keyword)
        @basicKeywords.push(
          {
            radix: keywordElements?[2].toLowerCase()
            keyword: keywordElements?[5]
            lowerCaseKeyword: keywordElements?[5].toLowerCase()
          }
        ) unless !keywordElements?

    # Now, build keyword lists for array elements in hdfs files
    @otherSimpleKeywords = []

    # Detection.Criteria(x)
    @otherSimpleKeywords.push(
      {
        pattern: /^\s*detection\.criteria\([0-9]+\)\.([a-z]*)\s*$/i
        keywordArray: resourceFileToArray 'completions-detection.txt'
        keywordType: 'property'
      }
    )

    # Sudo(x)
    @otherSimpleKeywords.push(
      {
        pattern: /^\s*sudo\([0-9]+\)\.([a-z]*)\s*$/i
        keywordArray: ['Command']
        keywordType: 'property'
      }
    )

    # Source(x)
    @otherSimpleKeywords.push(
      {
        pattern: /\.source\([0-9]+\)\.([a-z]*)\s*$/i
        keywordArray: resourceFileToArray 'completions-source.txt'
        keywordType: 'property'
      }
    )

    # Compute(x)
    @otherSimpleKeywords.push(
      {
        pattern: /\.compute\([0-9]+\)\.([a-z]*)\s*$/i
        keywordArray: resourceFileToArray 'completions-compute.txt'
        keywordType: 'property'
      }
    )

    # Step(x)
    @otherSimpleKeywords.push(
      {
        pattern: /\.step\([0-9]+\)\.([a-z]*)\s*$/i
        keywordArray: resourceFileToArray 'completions-step.txt'
        keywordType: 'property'
      }
    )

    # #include and #define
    @otherSimpleKeywords.push(
      {
        pattern: /^\s*#([a-z]*)\s*$/i
        keywordArray: ['define', 'include']
        keywordType: 'import'
      }
    )

    # Detection Types
    @otherSimpleKeywords.push(
      {
        pattern: /^\s*detection\.criteria\([0-9]+\)\.type\s*=\s*"?([a-z]*)"?\s*$/i
        keywordArray: resourceFileToArray 'completions-detection-type.txt'
        keywordType: 'constant'
      }
    )

    # Source Types
    @otherSimpleKeywords.push(
      {
        pattern: /\.source\([0-9]+\)\.type\s*=\s*"?([a-z]*)"?\s*$/i
        keywordArray: resourceFileToArray 'completions-source-type.txt'
        keywordType: 'constant'
      }
    )

    # Compute Types
    @otherSimpleKeywords.push(
      {
        pattern: /\.compute\([0-9]+\)\.type\s*=\s*"?([a-z]*)"?\s*$/i
        keywordArray: resourceFileToArray 'completions-compute-type.txt'
        keywordType: 'constant'
      }
    )

    # Step Types
    @otherSimpleKeywords.push(
      {
        pattern: /\.step\([0-9]+\)\.type\s*=\s*"?([a-z]*)"?\s*$/i
        keywordArray: resourceFileToArray 'completions-step-type.txt'
        keywordType: 'constant'
      }
    )

    # References to EmbeddedFiles
    @otherSimpleKeywords.push(
      {
        pattern: /=\s*([a-z]*)\s*$/i
        keywordArray: ['EmbeddedFile', 'Column']
        keywordType: 'constant'
      }
    )

###
# resourceFileToArray
###
resourceFileToArray = (pFilename) ->
  tempContent = fs.readFileSync path.resolve(__dirname, '..', pFilename)
  tempContent.toString().replace('\r', '').split('\n').filter((l) -> (l?.trim().length > 0))
