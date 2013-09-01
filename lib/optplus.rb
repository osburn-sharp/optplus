#
# Author:: Robert Sharp
# Copyright:: Copyright (c) 2013 Robert Sharp
# License:: Open Software Licence v3.0
#
# This software is licensed for use under the Open Software Licence v. 3.0
# The terms of this licence can be found at http://www.opensource.org/licenses/osl-3.0.php
# and in the file copyright.txt. Under the terms of this licence, all derivative works
# must themselves be licensed under the Open Software Licence v. 3.0
# 
#
require 'optparse'
require 'colored'
require 'abbrev'

class OptPlus
  
  def self.usage(txt)
    @@_banner = txt
  end
  
  def self.description(*lines)
    @@_description = lines
  end
  
  def self.describe(action, description)
    @@_actions ||= Array.new
    @@_actions << action.to_s
    @@_descriptions ||= Hash.new
    @@_descriptions[action] = description
  end
  
  def self.help(action, *lines)
    @@_help ||= Hash.new
    @@_help[action] = lines
  end
  
  def self.run!
    
    me = self.new
    
    if me._needs_help? then
      me._help_me
    elsif me._args.length > 0 then
      action = me.next_argument
      alup = @@_actions.abbrev(action)
      if alup.has_key?(action) then
        me.send(alup[action].to_sym)
      else
        puts "Sorry, What?"
        puts ""
        me._get_help
      end
    else
      me._get_help
    end
  rescue OptionParser::InvalidOption => opterr
    puts "Error: Invalid Option".red.bold
    puts "I do not understand the option: #{opterr.args.join}"
  rescue OptionParser::InvalidArgument => opterr
    puts "Error: You have entered an invalid argument to an option".red.bold
    puts "The option in question is: #{opterr.args.join(' ')}"
  rescue OptionParser::AmbiguousOption => opterr
    puts "Error: You need to be clearer than that".red.bold
    puts "I am not be sure what option you mean: #{opterr.args.join}"
  rescue OptionParser::AmbiguousArgument => opterr
    puts "Error: You need to be clearer than that".red.bold
    puts "I am not sure what argument you mean: #{opterr.args.join(' ')}"
  rescue OptionParser::MissingArgument => opterr
    puts "Error: You need to provide an argument with that option".red.bold
    puts "This is the option in question: #{opterr.args.join}"
  rescue OptionParser::ParseError => opterr
    puts "Error: the command line is not as expected".red.bold
    puts opterr.to_s
  end
  
  def initialize
    @_help = false
    @options = Hash.new
    
    self.before_all if self.respond_to?(:before_all)
    
    @_optparse = OptionParser.new do |opts|
      
      opts.banner = "Usage: #{opts.program_name} #{@@_banner}"
      opts.separator ""
      
      @@_description.each do |dline|
        opts.separator "  " + dline
      end
      
      opts.separator ""
      opts.separator "Actions:"
      opts.separator ""
      @@_descriptions.each do |key, value|
        opts.separator "  #{key} - #{value}"
      end
      
      opts.separator ""
      opts.separator "Options:"
      opts.separator ""
      
      if @@_help.length > 0 then
        help_string = 'use with an action for further help'
      else
        help_string = 'you are looking at it'
      end
      options(opts) if self.respond_to?(:options)
      opts.on_tail('-h', '--help', help_string) do
        @_help = true
      end
      
    end

    @_args = @_optparse.permute(ARGV)
    
    self.before_actions if self.respond_to?(:before_actions)
  end
  
  attr_reader :_args
  
  def next_argument
    @_args.shift
  end
  
  def all_arguments
    args = @_args.dup
    @_args = Array.new
    return args
  end
  
  
  def _get_help
    puts @_optparse.help
    puts ""
  end
  
  def _needs_help?
    @_help
  end
  
  def set_option(key, value=true)
    @options[key] = value
  end
  
  def get_option(key)
    @options[key]
  end
  
  def option?(key)
    @options.has_key?(key)
  end
  
  def _help_me
    if _args.length > 0 then
      action = next_argument.to_sym
      if @@_help.has_key?(action) then
        # valid help so use it
        puts "Help for #{action}"
        puts ""
        @@_help[action].each do |aline|
          puts aline
        end
        puts ""
        return
      elsif @@_actions.include?(action)
        puts "Sorry, there is no specific help for this action".yellow
        puts ""
        _get_help
        return
      else
        puts "Sorry, but I do not understand the action: #{action}".red.bold
        puts ""
        _get_help
        return
      end
    end
    _get_help
    
  end
  
end
