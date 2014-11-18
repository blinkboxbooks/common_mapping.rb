# Change log

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

