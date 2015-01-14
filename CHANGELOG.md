# Change log

## 0.1.4 ([#8](https://git.mobcastdev.com/Platform/common_mapping.rb/pull/8) 2015-01-14 15:06:59)

Deal with Storage Service omissions

### Bug fix

- Deal with the situation where the storage service doesn't have status information for the given token. (This *always* occurs with the fake storage service)

## 0.1.3 ([#7](https://git.mobcastdev.com/Platform/common_mapping.rb/pull/7) 2015-01-07 17:13:29)

Return

### Bugfix

- The `open` method should return the value the block yields when a block is given.

## 0.1.2 ([#6](https://git.mobcastdev.com/Platform/common_mapping.rb/pull/6) 2014-11-25 17:48:31)

Pluralise default folder

### Improvements

- The default schema file is `schemas` not `schema`
- Upgraded to needing the version of common_messaging from [#8](/Platform/common_messaging.rb/pull/8)

## 0.1.1 ([#5](https://git.mobcastdev.com/Platform/common_mapping.rb/pull/5) 2014-11-20 09:25:18)

Valid User Agent

### Bug fix

- Previous User-Agent was invalid.

## 0.1.0 ([#4](https://git.mobcastdev.com/Platform/common_mapping.rb/pull/4) 2014-11-18 16:05:09)

Legit

### New features

- Actually works!
- Can deal with HTTP and FILE urls passed in the mapping file from the storage service
- Opens files and downloads HTTP resources into temporary files, passing an IO object back for interaction with.

## 0.0.3 ([#3](https://git.mobcastdev.com/Platform/common_mapping.rb/pull/3) 2014-10-27 18:11:33)

Unescape URI components

### Improvement

- Allows URI encoded files to come through (allows spaces!)

## 0.0.2 ([#2](https://git.mobcastdev.com/Platform/common_mapping.rb/pull/2) 2014-10-08 13:06:55)

Deal with triple or single slash

### Bugfix

- URLs with a single or triple slash were failing to process (eg. `file:/path/to/stuff`)

## 0.0.1 ([#1](https://git.mobcastdev.com/Platform/common_mapping.rb/pull/1) 2014-10-06 14:35:20)

Correct the gemspec

### Improvement

- First release, mock only (while the Quartermaster is being spec'd out)

