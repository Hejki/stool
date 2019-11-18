# 🧰 stool
![badge-swift][] ![badge-platforms][] [![badge-spm][]][spm-link] [![badge-ci][]][ci] [![badge-licence][]][licence]

`stool` is command line tool that makes it easy to create and install your Swift tools.

## Quick Overview

#### Create project and open XCode
```console
$ stool init myTool
> Tool directory [/path/to/current/directory/myTool]: ⏎
> 🙌 Tool swift-validate was created at /path/to/current/directory/myTool
```

#### Build and install yout tool
<!-- ```console -->
<div class="highlight highlight-source-console">
<pre>
$ stool install
> [2/2] Linking myTool
> 👍 'myTool' was installed to '/usr/local/bin/'
</pre>
</div>

<pre>
<code>
$ stool install
> [2/2] Linking myTool
> 👍 'myTool' was installed to '/usr/local/bin/'
</code></pre>

## Instalation

For install *stool* command to your local machine, clone this repository and build *stool* to install *stool*.

```console
$ git clone https://github.com/Hejki/stool
$ cd stool
$ swift run stool install
```

That will build *stool* command and install it into `/usr/local/bin` folder. The install folder you can change in `.stool.yml` config file.

## Complete Usage Overview

#### First run

If you run *stool* for first time you must set global configuration properties, to do it just run `stool` command.
```console
$ stool
> 💩 The config file '/Users/you/.stool/config.yml' does not exist.
> 🏃‍♀️ stool initialization.
> Enter the default tools project directory location, empty if you don't want to set it.
> : <>

## Configuration Files

#### Project Config

#### Global Config

## Custom templates

Variables: name, target, currentDate

## TODO

* [ ] Template from git repository (install template)
* [ ] Global settings for default template
* [ ] List of templates
* [ ] config task for init .stool config file (conversation way)

[badge-swift]: https://img.shields.io/badge/Swift-5.1-orange.svg?logo=swift?style=flat
[badge-spm]: https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat
[spm-link]: https://swift.org/package-manager
[badge-platforms]: https://img.shields.io/badge/platform-mac-lightgray.svg?style=flat
[badge-ci]: https://travis-ci.com/Hejki/stool.svg
[ci]: https://travis-ci.com/Hejki/stool
[badge-licence]: https://img.shields.io/badge/license-MIT-black.svg?style=flat
[licence]: https://github.com/Hejki/stool/blob/master/LICENSE