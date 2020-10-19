# mimiq

![mimiq](https://user-images.githubusercontent.com/16457495/78473788-84b7cc80-776d-11ea-8c44-5d6c8e46f2cb.png)

<p align="center">
    <a href="https://github.com/wendyliga/mimiq/actions">
        <img src="https://github.com/wendyliga/mimiq/workflows/Mimiq%20CI/badge.svg?branch=master" alt="Build Status" />
    </a>
    <a href="#">
        <img src="https://img.shields.io/badge/Made%20with-Swift-orange" />
    </a>
    <a href="#">
        <img src="https://img.shields.io/github/license/wendyliga/mimiq" />
    </a>
    <a href="https://twitter.com/wendyliga">
        <img src="https://img.shields.io/badge/contact-@wendyliga-blue.svg?style=flat" alt="Twitter: @wendyliga" />
    </a>
</p>



mimiq is simple executable to record your Xcode simulator and convert it to several video type like gif, mp4 or mov.

# Installation

## Homebrew

if you don't have any idea about homebrew, homebrew is dependency manager on macos, to install homebrew
```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
of for more information visit [homebrew](https://brew.sh) website

install via homebrew

```shell
brew install wendyliga/core/mimiq
```

## Mint

```shell
# run without install
mint run wendyliga/mimiq

# or install
mint install wendyliga/mimiq
```

## Manual Install

Clone Repo
```
git clone https://github.com/wendyliga/mimiq.git
```

execute build script
```
make install
```

you will get `mimiq` executable, use it as you want
`mimiq` will installed at `/usr/local/bin`

## GUI Version
![mimiq-gui](https://user-images.githubusercontent.com/16457495/79256286-f1d80a00-7eb1-11ea-88db-58d870e663d5.jpg)

Mimiq have a GUI version for Mac user, you can install and use it with keyboard shortcut and ease of click, check it more [mimiq-gui](https://github.com/wendyliga/mimiq-gui).

# How To Use

## Start

![instruction](https://user-images.githubusercontent.com/16457495/76277122-65d33100-62ba-11ea-8e2d-151736319556.gif)

```
mimiq
```
Just simple to call `mimiq`, it will automatically detect current running simulator and record it for you

### Additional Options
#### 🆕 Set Custom Output type
previously `mimiq` is focus on recording GIF from your simulator, but from feedback on early user of mimiq, it has big potential, not just GIF.
so on `0.5.0`, mimiq extend itself to support outputing format like mp4 and mov also.

available output
```
- gif
- mov
- mp4
```

```shell
mimiq --output mp4
```

#### 🆕 Support Custom GIF Quality
you can specify what quality of GIF, mimiq will generate.

available quality
```
- low
- medium
- high
```
how to use
```shell
mimiq --quality high
```

#### Set custom Path
you can set where `mimiq` will place the generated output. for default, `mimiq` will generate output on desktop, but if you want to change it then, when start `mimiq` add this additional params

```shell
mimiq --path "~/...path/directory/folder"
```

#### Support Multiple Running Simulator
if you have multiple running simulator, then you need to spesify which simulator you want to `mimiq`.

get your running simulator by executing
```shell
mimiq list
```

example:

![Screen Shot 2020-03-29 at 22 01 38](https://user-images.githubusercontent.com/16457495/77852449-fbeadf00-7208-11ea-97bd-86b73d523ca7.jpg)

then record spesific simulato by its `UDID`

```shell
mimiq --udid 6ABC274C-76BB-483B-8DD6-8A9F8E486E0F
```

## Stop
```
press `enter`
```
to stop, just press `enter`. then grab your generated output

### Result

![video](https://user-images.githubusercontent.com/16457495/76277173-869b8680-62ba-11ea-94b4-cc28e6785bbf.gif)
    
```
*raft approx 1Mb gif size for 15s
```

# Upcomming Features
You can check upcomming feature on https://github.com/wendyliga/mimiq/projects/1

**New version** is available with this improvement, update your `mimiq` by

```shell
brew upgrade wendyliga/core/mimiq
```

# LICENSE
```
MIT License

Copyright (c) 2020 Wendy Liga

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
