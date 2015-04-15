# dashing-contrib 

[![Build Status](https://travis-ci.org/QubitProducts/dashing-contrib.svg?branch=master)](https://travis-ci.org/QubitProducts/dashing-contrib)


This project is an extension to Shopify's Dashing. Including this rubygem you will be able to:

 * Use all the built-in widgets
 * Extend `DashingContrib::RunnableJob` module to define, test jobs
 * Built-in jobs are only a couple of lines implementation, no repetitive copy and paste
 * Existing secret parameters is automatically loaded from `.env` file
 * All jobs have a final state (ok, warning, critical)
 * Rest API to get overall state summary
 * Rest API to trigger save history
 
Read each individual widget documentation to use dashing-contrib built-in widgets after the installation steps.

## Installation
Requires Ruby >= 1.9.3. Add this line to your Dashing's dashboard Gemfile:

    gem 'dashing-contrib', '~> 0.1.7'

Update dependencies:

    $ bundle

Add the following on top of the `config.ru`

    $: << File.expand_path('./lib', File.dirname(__FILE__))
    require 'dashing-contrib'
    require 'dashing'
    DashingContrib.configure
    
Include built-in CoffeeScript to `assets/javascripts/application.coffee`

    #=require dashing-contrib/assets/widgets

Include built-in SCSS to `assets/stylesheets/application.scss`

    //=require dashing-contrib/assets/widgets

Now you will be able to use the following widgets, click to see individual documentation:

 * [Rickshawgraph](https://github.com/QubitProducts/dashing-contrib/wiki/Widget:-Rickshawgraph)
 * [Sidekiq](https://github.com/QubitProducts/dashing-contrib/wiki/Widget:-Sidekiq)
 * [Pingdom Uptime](https://github.com/QubitProducts/dashing-contrib/wiki/Widget:-Pingdom-Uptime)
 * [Kue Status](https://github.com/QubitProducts/dashing-contrib/wiki/Widget:-Kue-Status)
 * [Nagios List](https://github.com/QubitProducts/dashing-contrib/wiki/Widget:-Nagios-List)
 * [Switcher](https://github.com/QubitProducts/dashing-contrib/wiki/Widget:-Switcher)
 * Dashing State (global alert if any widget is under critical state)

## dotenv

Shared job parameters are managed by `dotenv` gem. Add a `.env` file in your dashing project root. dashing-contrib will load your configuration from `.env` file automatically. An example `.env` file:

```ruby
NAGIOS_ENDPOINT: http://example.com/nagios3/cgi-bin
NAGIOS_USERNAME: dasher
NAGIOS_PASSWORD: readonly

PINGDOM_USERNAME: ping
PINGDOM_PASSWORD: pong
PINGDOM_API_KEY: pingpongpingpong
```

These values can be accessed in jobs `ENV['NAGIOS_ENDPOINT']`


## Job Definition

dashing-contrib gem provides a standard job definition wrapper. This replaces the 'SCHEDULE.every' call:

 * defines common data processing and testable/reusable modules
 * in addition to dashing's default 'updatedAt', introduced an optional `state` information used across all widgets
 

A custom job declaration example:

```ruby
module MyCustomJob
  # provides some dashing hooks 
  extend DashingContrib::RunnableJob
  
  # Overrides to extract some data for display
  # generated hash will be available for widget to access
  def self.metrics(options)
    { metrics: { failed: 500, ok: 123013 } }
  end
  
  # By default this always returns OK state
  # You can customize the state return value by lookup generated metrics and user provided options 
  def self.validate_state(metrics, options = {})
    # `metrics` parameter is the value return by `metrics` method
    failed_value = metrics[:metrics][:failed]
    
    return DashingContrib::RunnableJob::OK if failed_value == 0
    return DashingContrib::RunnableJob::WARNING if failed_value <= 100
    DashingContrib::RunnableJob::CRITICAL
  end
end
```

When using job:
```ruby
# make sure MyCustomJob module is required
# default interval is every 30s and job is executed once at start
MyCustomJob.run(event: 'custom-job-event', every: '20s')

# Custom job also has a block syntax if you are setting up some global settings
MyCustomJob.run(event: 'custom-job-event') do
  # setup redis client etc
end

# metrics and validate_state method will be able to use `my_custom_param` and `custom_threshold`
# to make configurable metrics fetch and state validation
MyCustomJob.run(event: 'custom-job-event', my_custom_param: 123, custom_threshold: 3)


# Override rufus-scheduler configuraiton using scheduler hash settings
MyCustomJob.run(event: 'custom-job-event', my_custom_param: 123, custom_threshold: 3, scheduler: { first_in: 10 })
```


Take a look some build-in jobs as example:

 * [dashing-contrib/jobs/sidekiq.rb](https://github.com/QubitProducts/dashing-contrib/blob/master/lib/dashing-contrib/jobs/sidekiq.rb)
 * [dashing-contrib/jobs/kue.rb](https://github.com/QubitProducts/dashing-contrib/blob/master/lib/dashing-contrib/jobs/kue.rb)
 * [dashing-contrib/jobs/nagios_list.rb](https://github.com/QubitProducts/dashing-contrib/blob/master/lib/dashing-contrib/jobs/nagios_list.rb)
 * [dashing-contrib/jobs/pingdom_uptime.rb](https://github.com/QubitProducts/dashing-contrib/blob/master/lib/dashing-contrib/jobs/pingdom_uptime.rb)
 * [dashing-contrib/jobs/dashing-state.rb](https://github.com/QubitProducts/dashing-contrib/blob/master/lib/dashing-contrib/jobs/dashing-state.rb)
 
This is nice that backend data fetching can be now unit tested and reused. Dashing widget view layer can reuse the same job processor and present data in multiple forms. 


# Widget State

All built-in jobs managed by 'DashingContrib::Runnable' assumes each widget instance has a 'state' under ok, warning or critical. We suggest your custom widget should also follow this convension.

This gem creates an additional REST API, as well as a widget to show a global healthness of the system. This is awesome if you would like to build some physical alert system around it.

`GET http://{dashing_endpoint}/api/states`

```json
{
    "ok": 2,
    "warning": 0,
    "critical": 0,
    "detailed_status": {
      "dashboard": {
        "state": "ok",
        "title": "Dashboard",
        "updated_at": 1403823187
      },
      "nagios-list": {
        "state": "ok",
        "title": "Nagios Checks",
        "updated_at": 1403823178
      }
    }
}
```

# Persistent History

A new REST endpoint allows to force keep a snapshot of current events data and update the history.yml yaml file. 

`Post http://{dashing_endpoint}/api/history/save`


## How to contribute

There are a couple of ways to contribute. Brining those widgets scattered in github, in multiple format into this repository. They usually falling into the following categories:

 * Widgets, common widgets should be generic solution to a common requirements. e.g. line graph, better clock with common functionalities. Documentation should be written as a README.md file under widget's own directory, include a preview.png file in the widget folder.
 * Jobs utils, common Job data processing for graphing purpose 
 * Fix and add test
 * Improve documentation
