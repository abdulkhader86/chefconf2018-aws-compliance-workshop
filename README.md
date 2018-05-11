# Continuous Compliance on AWS with Chef Automate

## Summary

This [reveal.js](https://github.com/hakimel/reveal.js/) presentation contains the material used during the ChefConf 2018 workshop titled "Continuous Compliance on AWS with Chef Automate".

## Summary

  1. Chef Automate 2 Intro
  1. Detect
      1. Adding EC2/API Node Managers
      1. Scanning AWS Regions and EC2 Instances
      1. Writing a SSH Baseline Profile (wrapper of DevSec SSH Baseline)
      1. Scanning Nodes Using Custom Profile via Automate
  1. Correct
      1. Writing a SSH Hardening Cookbook (wrapper of DevSec SSH Hardening)
      1. Testing Locally via Test Kithen
      1. Uploading to a Chef Server
      1. Bootstrapping a Node via Knife
  1. Automate
      1. Scheduling Scans in Automate
      1. Creating Notifications

## How to View

### Basic Viewing
Download a copy of this repository and open the index.html file directly in your browser.

### Full Viewing (Not Required)
Some reveal.js features, like external Markdown and speaker notes, require that presentations run from a local web server. The following instructions will set up such a server as well as all of the development tasks needed to make edits to the reveal.js source code.

  1. Install [Node.js](http://nodejs.org/) (4.0.0 or later)
  2. Clone this repository
  3. Install dependencies
     ```sh
     $ npm install
     ```
  4. Serve the presentation and monitor source files for changes
     ```sh
     $ npm start
     ```
  5. Open <http://localhost:8000> to view your presentation
     > You can change the port by using `npm start -- --port=8001`.
