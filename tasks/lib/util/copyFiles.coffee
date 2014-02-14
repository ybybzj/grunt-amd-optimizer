grunt = require 'grunt'
_ = require 'underscore'
FS = require 'fs'
module.exports = (srcPath, destPath, copyOptions)->
  copyCount = 0
  copyOptions = _.extend {
      encoding: grunt.file.defaultEncoding
      process: false
      noProcess: []
      copyExcludes:[]
      mode: false,
      keepDest: true
    },copyOptions
  if copyOptions.keepDest is false
    grunt.verbose.writeln "Deleting #{destPath.yellow} ..."
    grunt.file.delete destPath, {force:true}
  excludePatterns = copyOptions.copyExcludes.map (pattern)->'!'+pattern
  filePatterns = ['**/*.*'].concat(excludePatterns)
  filesMap = grunt.file.expandMapping  filePatterns,destPath,{expand:true,filter:'isFile', cwd:srcPath} 
  # console.log filesMap
  filesMap.forEach (filePair)->
    src = filePair.src
    dest = filePair.dest
    grunt.verbose.writeln "Copying #{src.cyan} -> #{dest.cyan}"
    grunt.file.copy src, dest, copyOptions
    if copyOptions.mode isnt false 
      fs.chmodSync(dest, if copyOptions.mode is true then fs.lstatSync(src).mode else copyOptions.mode)
          
    copyCount++
  if copyCount
    grunt.log.write "Copied #{copyCount.toString().cyan} files"
  grunt.log.writeln()
  