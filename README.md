# OPTPLUS

Optplus is a wrapper around optparse aimed at making optparse-based scripts easier to write and
offering enhanced functions for little extra effort. It has a Thor-like structure but is
strictly optparse based with none of the complications that thor presents.

**GitHub:** [https://github.com/osburn-sharp/optplus](https://github.com/osburn-sharp/optplus)

**RubyDoc:** [http://rubydoc.info/github/osburn-sharp/optplus/frames](http://rubydoc.info/github/osburn-sharp/optplus/frames)

**RubyGems:** [https://rubygems.org/gems/optplus](https://rubygems.org/gems/optplus)

## Installation

Optplus is available as a gem. To install:

    # gem install optplus
    
To use optplus, just require it. See below for examples.

## Getting Started

To use Optplus, first define a class that inherits from {Optplus::Parser}, add an options
method to include your own options (Optplus defines a few for you) and then define some
action methods to do the work. After the class definition use the {Optplus::Parser.run!}
class method to run the parser. 

### Simple Example

Here is a simple example:

    require 'optplus'
    
    class Mycli < Optplus::Parser
    
      usage "actions [params] [options]"
      
      description "a brief description",
        "that can extend over multiple lines"
        
      def options(opts)
      
        # define your own options just like with optparse
        opts.on('-a', '--all', 'show all the items') do
          # optplus provides a convenient way to set and get options
          set_option :all
        end
        
      end
      
      describe :show, 'show all of the items that match the string given'
      def show
        matches = next_argument_or_error('You must provide a string to match')
        
        # do the stuff
        
      end
      help :show, "A more details description of the show action",
        "that can again spread over multiple lines",
        "and is displayed when the user types mycli show -h"
        
    end
    
    Mycli.run! # don't forget!
    
Optplus allows minimal unambiguous abbreviations for actions using the Array#abbrev
method. Single letters will not be recognised but two or more are generally enough.
It is worth planning your action names to enable convenient abbreviations to be used.

## General Description

Optplus is nothing more than a convenient wrapper around Optparse aimed at accelerating
the writing of useful scripts that work in the style of actions, parameters and options.
It uses Optparse#permute to evaluate the command line so that options can be scattered
anywhere on the command line and will be evaluated all in the same level. It also
provides the ability to nest a parser so that actions can have sub-actions - see below
for further details.

Using Optplus involves the following:

* define a class that inherits from {Optplus::Parser}

* specify some preamble help information using the following meta-methods

> **usage** -- define the order of any actions, parameters or options to display in
  the usage line. Does not need "Usage etc" cos this is provided automatically

> **description** -- multiline description displayed at the top of the help text. If
  you want more details, use the readme action.
  
* define a **#before_all** method if you need something to be done before any optparse
  methods or anything else. It expects no parameters.

* define an **#options** method to add your own option switches in the same manner as Optparse.
  You must provide a parameter to pass in the optparse object (e.g. opts).
  There are some convenience methods that can also be called with the optparse object
  to add some common option switches. See below for more details.
  
* define a **#before_actions** method -- this method is called after the optplus parser has
  been evaluated but before any actions are executed. Use this to set up common objects
  for these actions. It expects no parameters.
  
* For each action you need to define the following
  
> **describe** -- links an action (as a symbol) to a one line description.

> **action_ method** -- for the action itself, having the same name as the symbol above

> **help** - links the action to multi-line help text that will be displayed when
  the --help option is used with the action

* And finally, if you need to tidy up afterwards you can define an after_actions
  method.

Within an action method you can obtain parameters using the {Optplus::Parser#next_argument}
method. This will return nil if there is no next argument, but to make life a little easier
you can use {Optplus::Parser#next_argument_or} to define a default if there is no argument, or
{Optplus::Parser#next_argument_or_error} to specify an error message if there is no argument.
The latter will raise an exception that is trapped by {Optplus::Parser.run!} to display
as a sensible error message.

Note that Optparser may raise a number of exceptions, for example where a type is defined
but the wrong type entered, and Optplus will trap these and display appropriate error 
messages when this occurs so you don't have to worry about them.

There are a couple of example scripts that can be used to see what Optplus does.
See Tests below.

### Default and Extra Option Switches

Optplus provides a -h or --help option switch by default. Two other option switches can be added
simply by calling helper methods:

    debug_option(opts) # add a debug switch (-D, --debug)
    
    puts "In debug mode" if get_option(:debug)
    
    verbose_option(opts) # add a verbose switch (-V, --verbose)
    
    puts "In verbose mode" if get_option(:verbose)
    
You can change the short-form switch by adding a different one:

    debug_option(opts, '-d') 

### Options helpers

To make things a little easier there are a couple of methods to set and read local
options:

**{Optplus::Parser#set_option}** that can be used to set an option with the given :key
  to either true (if no object is passed as the second parameter) or to the given object.
  
**{Optplus::Parser#get_option}** returns the value of the set option for the given :key

**{Optplus::Parser#option?}** returns true if the given option has been defined

For example:

    set_option :all
    set_option :config, path
    set_option :environment, env
    
    if option? :all then
      # do something
      params = get_config(get_option(:config))
    end
    
You can always define instance variables if you prefer.

### Handling Errors

Optplus should take care of parsing errors and the like without you having to get involved.
However, there may be circumstances when you need to exit the script in a hurry and
you may need to tidy up if you have already set something up (e.g. in a before_actions method).
The {Optplus::Parser#exit_on_error} method is provided to help. Calling the method
will raise an exception that will be trapped to ensure that, if necessary, the 
{Optplus::Parser#after_actions} method is called and the script exits with code 1. It will
also display the message if provided.

## Nesting Actions

Optplus allows you to define sub-actions or sub-commands for an action if you want to.
The general syntax would be: action sub [param] [options].

First you need to define a nested parser class, inheriting from {Optplus::NestedParser}
instead of {Optplus::Parser}. This is similar to the main parser but should only contain
a usage and description call, action methods, descriptions and help text.

Once this nested class is defined you must define the action to which it will belong
using the {Optplus::Parser.nest_parser} method. Here is a simple example:

    class MyParser < Optplus::Parser
      
      usage "action [param] [options]"
      
      description "simple parser"
      
      def options(opts)
        # etc
      end
      
      class SubParser < Optplus::NestedParser
      
        usage "action subaction [params] [options]"
        
        description "do things relating to action"
        
        describe :list, 'list actions'
        def list
          # do the listing
        end
        help :list 'describe what list does'
        
      end
      
      nest_parser :action, SubParser, 'do things with actions'
      
    end
    
    MyParser.run!
    
The methods for getting arguments and options etc that are available in MyParser are
also available in SubParser but you cannot set_option in SubParser and you cannot add
option switches that are specific to the action. If you want to get into that you may
be better trying Thor.

Help for nested commands works like this:

* the help/usage text for the script should contain the name of the action and the
  description provided with {Optplus::Parser#nest_parser} just like all of the other
  actions.
  
* applying the -h switch with the action will display the usage, description and sub-actions
  just as for the main help but will not repeat the option switches. There is a note
  to remind you how to see them though (plain -h)
  
* applying the -h switch to an action and sub-action that has defined its own help text will
  do exactly the same as it would if it was just an action
  
And finally, don't forget that sub-actions can take parameters but obviously the action
to which they belong cannot (cos it will be interpreted as a sub-action)
    
## Code Walkthrough

The code is simple. The class methods that are called in defining a parser use class
instance variables to store the data defined (e.g. describe stores the action and the description
in a hash). The {Optplus::Parser.run!} method creates an instance of the parser class
and the constructor will call the before methods, build the Optparse object with all
the tedious separators, call the options method to add your own option switches, and
then read the first argument as an action.

It uses Array#abbrev to convert abbreviated action names into the full action and then
calls the method. Optparse exceptions and Optplus exceptions are trapped for convenient
error messaging.

## Dependencies

Ruby  1.9.3
abbrev standard library
colored gem

Check the {file:Gemfile} for dependencies.

## Documentation

Documentation is best viewed using Yard and is available online 
at [RubyDoc](http://rdoc.info/github/osburn-sharp/optplus/frames)

## Testing/Modifying

There are no rspec tests provided, but there are two test scripts: {file:test/my_parser.rb}
and {file:test/my_nested_parser.rb}. They are not comprehensive, but they do test 
out various things.

## Bugs

Details of any unresolved bugs and change requests are in {file:Bugs.rdoc Bugs}

## Changelog

See {file:History.txt} for a summary change history

## Copyright and Licence

Copyright (c) 2013 Robert Sharp

This software is licensed under the terms defined in {file:LICENCE.rdoc}

The author may be contacted by via [GitHub](http://github.com/osburn-sharp)

## Warranty

This software is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantibility and fitness for a particular purpose.
