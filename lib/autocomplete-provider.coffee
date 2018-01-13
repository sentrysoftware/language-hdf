fs = require 'fs'
path = require 'path'

basicKeywordPattern = /^\s*((([a-z]+)\.)*)([a-z]*)\s*$/i
detectionKeywordPattern = /^\s*detection\.criteria\([0-9]+\)\.([a-z]*)\s*$/i
sudoKeywordPattern = /^\s*sudo\([0-9]+\)\.([a-z]*)\s*$/i
sourceKeywordPattern = /\.source\([0-9]+\)\.([a-z]*)\s*$/i
computeKeywordPattern = /\.compute\([0-9]+\)\.([a-z]*)\s*$/i
stepKeywordPattern = /\.step\([0-9]+\)\.([a-z]*)\s*$/i

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
      radix = lineElements?[1]
      prefix = lineElements?[4]

      completions = []
      for keywordEntry in @basicKeywords when radix.toLowerCase() == keywordEntry.radix and keywordEntry.lowerCaseKeyword.startsWith(prefix.toLowerCase())
        completions.push(@buildKeywordCompletion(keywordEntry.keyword))
      return completions

    # Check for single-keywords (after Detection.Criteria(x), Source(x), or Compute(x))
    for {pattern, keywordArray} in @otherSimpleKeywords
      lineElements = pattern.exec(line)
      if lineElements?
        prefix = lineElements?[1]
        completions = []
        for keyword in keywordArray when keyword.toLowerCase().startsWith(prefix.toLowerCase())
          completions.push(@buildKeywordCompletion(keyword))
        return completions

    completions

  onDidInsertSuggestion: ({editor, suggestion}) ->
    setTimeout(@triggerAutocomplete.bind(this, editor), 1) if suggestion.type is 'property'

  triggerAutocomplete: (editor) ->
    atom.commands.dispatch(atom.views.getView(editor), 'autocomplete-plus:activate', {activatedManually: false})

  loadKeywords: ->
    @basicKeywords = []
    fs.readFile path.resolve(__dirname, '..', 'completions-basic.txt'), (error, content) =>
      for keyword in content.toString().replace('\r', '').split('\n') when keyword?.trim().length > 0
          keywordElements = basicKeywordPattern.exec(keyword)
          @basicKeywords.push({
              radix: keywordElements?[1].toLowerCase()
              keyword: keywordElements?[4]
              lowerCaseKeyword: keywordElements?[4].toLowerCase()
            }) unless !keywordElements?

    @otherSimpleKeywords = []

    detectionKeywordArray = []
    fs.readFile path.resolve(__dirname, '..', 'completions-detection.txt'), (error, content) =>
      for keyword in content.toString().replace('\r', '').split('\n') when keyword?.trim().length > 0
        detectionKeywordArray.push(keyword)
    @otherSimpleKeywords.push({
      pattern: detectionKeywordPattern
      keywordArray: detectionKeywordArray
    })

    sudoKeywordArray = []
    fs.readFile path.resolve(__dirname, '..', 'completions-sudo.txt'), (error, content) =>
      for keyword in content.toString().replace('\r', '').split('\n') when keyword?.trim().length > 0
        sudoKeywordArray.push(keyword)
    @otherSimpleKeywords.push({
      pattern: sudoKeywordPattern
      keywordArray: sudoKeywordArray
    })

    sourceKeywordArray = []
    fs.readFile path.resolve(__dirname, '..', 'completions-source.txt'), (error, content) =>
      for keyword in content.toString().replace('\r', '').split('\n') when keyword?.trim().length > 0
        sourceKeywordArray.push(keyword)
    @otherSimpleKeywords.push({
      pattern: sourceKeywordPattern
      keywordArray: sourceKeywordArray
    })

    computeKeywordArray = []
    fs.readFile path.resolve(__dirname, '..', 'completions-compute.txt'), (error, content) =>
      for keyword in content.toString().replace('\r', '').split('\n') when keyword?.trim().length > 0
        computeKeywordArray.push(keyword)
    @otherSimpleKeywords.push({
      pattern: computeKeywordPattern
      keywordArray: computeKeywordArray
    })

    stepKeywordArray = []
    fs.readFile path.resolve(__dirname, '..', 'completions-step.txt'), (error, content) =>
      for keyword in content.toString().replace('\r', '').split('\n') when keyword?.trim().length > 0
        stepKeywordArray.push(keyword)
    @otherSimpleKeywords.push({
      pattern: stepKeywordPattern
      keywordArray: stepKeywordArray
    })

    return

  buildKeywordCompletion: (keyword) ->
    completion =
      type: "keyword"
      description: ""
      descriptionMoreURL: ""
      text: "#{keyword}"

    completion

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()
