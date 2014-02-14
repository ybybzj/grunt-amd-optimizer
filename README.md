# grunt-dolphin-optimizer

> Optimize tvs files utilizing "uglify-js", "clean-css" and "html-minifier", 
  resolve all the resource paths referred by the files and output files ready to deploy

## Getting Started
This plugin requires Grunt `~0.4.2`

If you haven't used [Grunt](http://gruntjs.com/) before, be sure to check out the [Getting Started](http://gruntjs.com/getting-started) guide, as it explains how to create a [Gruntfile](http://gruntjs.com/sample-gruntfile) as well as install and use Grunt plugins. Once you're familiar with that process, you may install this plugin with this command:

```shell
npm install grunt-dolphin-optimizer --save-dev
```

Once the plugin has been installed, it may be enabled inside your Gruntfile with this line of JavaScript:

```js
grunt.loadNpmTasks('grunt-dolphin-optimizer');
```

## The "dolphin-optimizer" task

### Overview
In your project's Gruntfile, add a section named `dolphin-optimizer` to the data object passed into `grunt.initConfig()`.

```js
grunt.initConfig({
  dolphin-optimizer: {
    options: {
      // Task-specific options go here.
    },
    your_target: {
      // Target-specific file lists and/or options go here.
    },
  },
});
```

### Options

#### options.srcPath
Type: `String`
Default value: `src`

A string value that is used to designate src directory path.

#### options.buildPath
Type: `String`
Default value: `build`

A string value that is used to designate output directory path.

#### options.embeded
Type: `String|Boolean`
Default value: `css`

'css' stands for only embed stylesheets;
'js' stands for only embed js code;
true stands for embed both js code and stylesheets;
false do not embed either;
this setting is overwritten by the inline data-how="xxx" attribute.

#### options.optimizeOptions
Type: `Object`
Default value: `{
        js: true,
        css: true,
        html:{ 
          removeComments: true
        }
}`

Set 'uglify-js','clean-css' and 'html-minifier' options respectively;
true means use default options of each minifiers
### Usage Examples

#### Default Options

```js
grunt.initConfig({
  dolphin-optimizer: {
    options: {
      srcPath: 'src',
      buildPath: 'build',
      embeded:'css',
      optimizeOptions:{
        //use 'uglify-js'
        js: true,
        //use 'clean-css'
        css: true,
        //use 'html-minifier'
        html:{ 
          removeComments: true
        }
      }
    },
  },
});
```


## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Release History
_(Nothing yet)_
