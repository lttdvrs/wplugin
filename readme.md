# Plugin Version Scanner WordPress

## Overview
The Plugin Version Scanner is a Ruby-based utility designed to scan WordPress websites to detect and report the versions of plugins installed. It provides a customizable way to check for plugin versions using specified patterns in the HTML source code, comments, and meta tags.

With help of WPScan [WPScan](https://wpscan.com/)

## Installation

Before running the script, ensure you have Ruby installed on your system and the required gems. You can install the necessary gems using the following command:

### Requirements
Required Gems:
  - `open-uri`
  - `nokogiri`
  - `yaml`
  - `psych`
  - `net/http`
  
```bash
gem install nokogiri yaml psych net-http
```

## Usage
```bash
ruby plugins.rb example.yml http://example.com
```
