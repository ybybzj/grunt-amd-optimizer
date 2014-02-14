_ = require 'underscore'
grunt = require 'grunt'
Util = require './util'
Promise = Util.promise
HtmlObj = require './HtmlObj'
PATH = require 'path'
Chalk = require 'chalk'


#hepler


#class definition
class HtmlOptimizerTask
  constructor: (task)->
    self = @
    @done = task.async()
    @origTask = task
    @options = 
      task.options HtmlOptimizerTask.Defaults
    # @options = _.extend({},options)
    @options.embedded = 
      js: if (@options.embedded is true) or (@options.embedded is 'js') then true else false
      css: if (@options.embedded is true) or (@options.embedded is 'css') then true else false
    # console.log @options
    @init()

  init: ->
    #First of all, copy all src files into the build directory
    grunt.log.writeln Chalk.blue.bgWhite "Start copying src files..."
    grunt.log.writeln "from: #{Chalk.gray @options.srcPath}" 
    grunt.log.writeln "to: #{Chalk.gray @options.buildPath}"
    Util.copyFiles @options.srcPath,@options.buildPath,{copyExcludes:['**/*.html','src/**/*.*'], keepDest: false}
    grunt.log.ok Chalk.cyan "Copying succeeded!"
    grunt.log.writeln ""
    #Prepartion base on build directory
    fileMaps = 
      grunt.file.expandMapping(
        '**/*.tvs',
        @options.buildPath,
        {cwd:@options.srcPath}
      )
    # console.log fileMaps
    grunt.log.writeln ""
    grunt.log.writeln "#{Chalk.blue.bgWhite 'Start initializing html objects...'}"
    @htmlObjs =_.flatten(
      for fileObj in fileMaps
        # console.log fileObj.cssPath
        dest = fileObj.dest
        src = fileObj.src.filter (s)->
          if not grunt.file.exists(s)
            grunt.log.error("Source file #{s} not found.")
            false
          true
        src.map (s)->
          src: dest 
          orgSrc: src
          dest: Util.fs.changeExtName dest, '.html'
    ).map(
      (fm)=>
        htmlObj = new HtmlObj(fm,@options)
        # console.log htmlObj.content
        htmlObj
    )
  run: ->
    grunt.log.writeln ""
    grunt.log.writeln "#{Chalk.blue.bgWhite 'Start optimizing (include minifying,concatenation, and relative path fixing)...'}"
    Promise.all(@htmlObjs.map (htmlObj)->
      htmlObj.processResources()
      .then((content)->
        # grunt.log.writeln "Start to output optimized html... ==> #{htmlObj.paths.dest}"
        grunt.file.write(htmlObj.paths.dest,content)
        grunt.log.ok "#{"Output html succeeded!".green} (#{htmlObj.paths.dest})"
      ).then(->
        # grunt.log.writeln "Start to delete input tvs file... ==> #{htmlObj.paths.src}"
        grunt.file.delete(htmlObj.paths.src,{force:true})
        grunt.log.ok "#{"Delete tvs succeeded!".cyan} (#{htmlObj.paths.src})"
      )
    ).then(=>
      grunt.log.writeln ""
      grunt.log.writeln Chalk.green.bgYellow "Generated external files:"
      @htmlObjs.forEach (htmlObj)->
        htmlObj.outputExternalFiles.forEach (outFile)-> grunt.log.writeln Chalk.gray outFile
    ).then(=>
      grunt.log.writeln ""
      grunt.log.writeln Chalk.blue.bgWhite "Begin clean up..."
      grunt.file.expand(
        {cwd:@options.srcPath,filter:'isFile'}
        '**/*.tvs'
      ).forEach (tvsFilePath)=>grunt.file.delete PATH.join(@options.srcPath,tvsFilePath), force:true
      @htmlObjs.forEach (htmlObj)->
        htmlObj.generatedFiles.forEach (gf)=>
          grunt.file.delete PATH.join(htmlObj.orgFileBasePath,gf), force:true
      grunt.log.ok Chalk.cyan "Clean up finished!"
    )
    .then(=>grunt.log.writeln "";grunt.log.ok Chalk.cyan "Optimizing succeeded!";@done())
    .catch(grunt.log.error)
    return


  #static properties#
  @Defaults :
    srcPath: 'src'
    buildPath: 'build'
    #'css' => only embed css;
    #'js' => only embed javascript;
    #true => embed all css and js;
    #false => do not embed css or js;
    embedded:'css'
    optimizeOptions:
      #'uglify-js' options
      js: true
      #'clean-css' options
      css: true
      #'html-minifier' options
      html: 
        removeComments: true
        collapseWhitespace: true
    
  
  @taskName: 'dolphin-optimizer'
  @taskDescription: 'Optimize tvs files utilizing "uglify-js", "clean-css" and "html-minifier", 
  resolve all the resource paths referred by the files and output files ready to deploy'

  @registerWithGrunt: (grunt)->
    grunt.registerMultiTask HtmlOptimizerTask.taskName,
      HtmlOptimizerTask.taskDescription, ->
        task = new HtmlOptimizerTask(@)
        task.run()
        return
      
    return

module.exports = HtmlOptimizerTask