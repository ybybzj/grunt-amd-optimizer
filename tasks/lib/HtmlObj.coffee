grunt = require 'grunt'
Util = require './util'
_ = require 'underscore'
PATH = require 'path'
Promise = Util.promise
UglifyJS = require 'uglify-js'
CleanCSS = require 'clean-css'
HtmlMinifier = require 'html-minifier'


#global regexes
scriptNodeReg = /<script[^>]*>(?:[\s\S]*?)<\/script\s*>/ig
stylesheetNodeReg = /(<link([^>]*)\/>)|(<style[^>]*>(?:[\s\S]*?)<\/style\s*>)/ig
linkHrefReg = /^<link[^>]+href=(?:"|')\s*(\S+)\s*(?:"|')/i
scriptSrcReg = /^<script[^>]+src=(?:"|')\s*(\S+)\s*(?:"|')/i
styleTagReg = /<(\/)?style(\s+[^>]+)*>/ig
scriptTagReg = /<(\/)?script(\s+[^>]+)*>/ig
referenceHowReg = /^<[^>]+data-how=(?:'|")(\w+)(?:'|")/i
howReg = /data-how=(?:'|")(\w+)(?:'|")/ig
endingHeadTagReg = /(<\/\s*head\s*>)/i
externalResourceUrlReg = /url\(([^\)]+)\)/ig
relativePathReg = /(^(?:\.|(?:\.\.))?[^\:\/][^\:]+$)/i
#helpers
NOOPTIMIZE = (o)->o
_getMatchPhrase = (input, reg)->
	result = input.match reg
	result?[1]
	

_genFileName = (type,pageName)->
	i = 1
	prefix = if type is 'js' then "#{pageName}.script." else "#{pageName}.style."
	ext = if type is 'js' then '.js' else '.css'
	-> prefix + (i++) + ext
# wrapWithComment = (str)->if str then "\n\t<!--inserted by depTraversal begin-->#{str}\n\t<!--inserted by depTraversal end-->\n" else ""



#HtmlObj Class
class HtmlObj
	constructor: (@paths,@options)->
		# console.log @options
		@init()

	init: ->
		@fileBasePath = PATH.dirname @paths.src
		@orgFileBasePath = PATH.dirname @paths.orgSrc
		@pageName = Util.fs.getFileNameWithoutExt @paths.src
		@genFileName = 
			js: _genFileName('js',@pageName)
			css: _genFileName('css',@pageName)
		@content = grunt.file.read(@paths.src)
		@outputExternalFiles = []
		@generatedFiles = []
		#prepare optimizers
		@optimizers = 
			js:
				if @options.optimizeOptions.js is true
					(input)->
						UglifyJS.minify(input,{fromString: true}).code
				else if _.isObject @options.optimizeOptions.js
					(input)=>
						UglifyJS.minify(input,_.extend({fromString: true},@options.optimizeOptions.js)).code
				else 
					NOOPTIMIZE
			css:
				if @options.optimizeOptions.css is true
					new CleanCSS().minify
				else if _.isObject @options.optimizeOptions.css
					new CleanCSS(@options.optimizeOptions.css).minify
				else 
					NOOPTIMIZE
			html: 
				if @options.optimizeOptions.html is true
					(input)->
						HtmlMinifier.minify(input,{})
				else if _.isObject @options.optimizeOptions.html
					(input)=>
						HtmlMinifier.minify(input,@options.optimizeOptions.html)
				else 
					NOOPTIMIZE
		
		@initResources()
		grunt.log.ok "htmlObj(#{@paths.src}) created!"
		return
	
	_makeNodeObj:(type,how,url,pos)->
		embedded = if how then how is 'embedded' else @options.embedded[type]
		_url = 
			#means node's content need to be combined and output to a single external file
			if how is undefined and not embedded 
				genUrl = PATH.join @fileBasePath,@genFileName[type]()
				@outputExternalFiles.push genUrl
				genUrl
			else
				if embedded is true then undefined else url
		outUrl = Util.fs.changeFileNameWithoutExt _url, Util.fs.getFileNameWithoutExt(_url) + '.min'
		pos:pos
		how:how
		outUrl : outUrl	
		embedded: embedded
		contentPromise:[]
	_getReplaceFun: (type, collection)->
		pos = 1
		if type is 'js'
			hrefReg = scriptSrcReg
			tagReg = scriptTagReg
		else
			hrefReg = linkHrefReg
			tagReg = styleTagReg
		(scontent)=>
			placeholderStr = ""
			how = _getMatchPhrase scontent, referenceHowReg
			# console.log how
			#do nothing if data-how="ignore" is set
			return scontent.replace(howReg,'') if how is 'ignore'

			isGenerated = /dolphin-traversal-generated/i.test scontent
			href = _getMatchPhrase scontent, hrefReg
			@generatedFiles.push href if isGenerated
			url = 
				if href
					if Util.fs.isUrl href then href else PATH.join(@fileBasePath,href)
				else
					undefined
			#when node collection is empty or current node's "how" is set or
			#last node in the collection has "how" setting, create a new node
			if collection.length is 0 or how or (collection[-1..-1][0] and collection[-1..-1][0].how)
				collection.push @_makeNodeObj(type,how,url,pos)
				if type is 'css'
					if pos is 1
						placeholderStr = '\n<insert-stylesheets-placeholder>\n'
				else
					placeholderStr = "<script-placeholder-begin>#{pos}<script-placeholder-end>"
				pos += 1

			
			nodeObj = collection[-1..-1][0]
			# generate ContentPromise
			getContent = (
				if url
					Util.getContent(url)
				else
					Promise.resolve(scontent.replace(tagReg,''))
			).then (content)=>
				if type is 'css'#only css need to resolve relative paths
					url ?= @paths.src
					@resolveResourcePath content, PATH.dirname url, nodeObj.outUrl
				else
					content
			nodeObj.contentPromise.push getContent
			placeholderStr
	initResources:->
		@scripts = []
		@stylesheets = []
		#prepare stylesheets
		@content = @content.replace stylesheetNodeReg, @_getReplaceFun('css',@stylesheets)
		#prepare scripts
		@content = @content.replace scriptNodeReg, @_getReplaceFun('js',@scripts)
		# console.log @content
		# console.log @stylesheets
		# console.log @scripts
	resolveResourcePath: (content, srcPath, destPath)->
		destPath ?= @paths.src
		destPath = PATH.dirname destPath
		getNewRelativePath = (oldRpath)-> 
			absPath = PATH.resolve srcPath, oldRpath
			Util.fs.pathToUrl PATH.relative destPath, absPath
		content.replace externalResourceUrlReg, (m,resourcePath)->
			#get rid of blank char and begin/end quotes
			resourcePath = resourcePath.replace(/\s+/g,'').replace(/^("|')/,'').replace(/("|')/,'')
			resRelativePath = _getMatchPhrase resourcePath,relativePathReg
			if resRelativePath is undefined
				return m
			else
				"url(#{getNewRelativePath resRelativePath})"

	_contentOptimizingPromises: (type,collection)->
		dilimiter = if type is 'js' then ';' else ''
		collection.map (contentObj)=>
			combinedContent = []
			optimizedContents = contentObj.contentPromise.map (getContent)=>
				getContent.then (content)=>
					@optimizers[type] content
			Promise.reduce optimizedContents, (oc)->
				combinedContent.push oc
			.then ->
				contentObj.finalContent = combinedContent.join(dilimiter)
				contentObj
	processResources:->
		# grunt.log.writeln "Begin to optimize ==>#{@paths.src}"
		Promise.all(
			@_contentOptimizingPromises 'js', @scripts
			.concat @_contentOptimizingPromises 'css', @stylesheets
		).then(=>
			#insert stylesheets
			@content = @content.replace /<insert-stylesheets-placeholder>/i, (placeholder)=>
				@stylesheets.map (styleObj)=>
					# console.log styleObj.outUrl 
					if styleObj.embedded
						"<style type=\"text/css\">#{styleObj.finalContent}</style>"
					else
						grunt.file.write(styleObj.outUrl,styleObj.finalContent)
						"<link type=\"text/css\" rel=\"stylesheet\" href=\"#{Util.fs.pathToUrl PATH.relative(@fileBasePath,styleObj.outUrl)}\"/>"
				.join "\n"
			#insert script
			indexedScripts =  _.indexBy(@scripts,'pos')
			@content = @content.replace /<script-placeholder-begin>(\d+)<script-placeholder-end>/ig,
				(placeHolder, pos)=>
					scriptObj = indexedScripts[pos]
					if scriptObj.embedded
						"\n<script type=\"text/javascript\">#{scriptObj.finalContent}</script>\n"
					else
						grunt.file.write(scriptObj.outUrl,scriptObj.finalContent)
						"\n<script type=\"text/javascript\" src=\"#{Util.fs.pathToUrl PATH.relative(@fileBasePath,scriptObj.outUrl)}\"></script>"
			# grunt.file.write(Util.fs.changeExtName(@paths.src,'opt'), @content)
			@content = @optimizers.html @content
			@cleanupGeneratedFiles()
			grunt.log.ok "#{"Content optimized".blue} (#{@paths.src})"
			@content
		)
	cleanupGeneratedFiles:()->
		for gf in @generatedFiles
			grunt.file.delete PATH.join(@fileBasePath,gf), force:true
	    
module.exports = HtmlObj