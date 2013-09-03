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
require 'optplus/errors'

module Optplus
  
  # == Optplus Parser
  #
  # A wrapper class that adds a little value to writing scipts
  # with optparse. Like Thor but without trying to do too much.
  #
  class Parser
    
    class << self
    
      # define the usage banner, less "Usage: <prog_name>"!
      #
      # For example: usage "[options] [actions] [filename]" becomes:
      # "Usage: progname [options] [actions] [filename]"
      #
      # @param [String] txt that is the banner
      def usage(txt)
        @_banner = txt
      end
      
      attr_reader :_banner
      
      # Adds a description to the help/usage
      #
      # This takes any number of string arguments and displays them as separate lines.
      #
      # @param [Array] lines of description text as variable arguments
      def description(*lines)
        @_description = lines
      end
      
      attr_reader :_description
      
      # Add a brief description for a specific action
      #
      # Add a little Thor-like description before each method. Unlike Thor,
      # you will not get told off if there is no corresponding method but
      # its probably a good idea if you add one.
      #
      # @param [Symbol] action to be described
      # @param [String] description of the action
      def describe(action, description)
        @_actions ||= Array.new
        @_actions << action.to_s
        @_descriptions ||= Hash.new
        @_descriptions[action] = description
      end
      
      attr_reader :_actions
      attr_reader :_descriptions
      
      # add a block of helpful text for an action
      #
      # Adds all of the arguments as lines to display when you use the help
      # switch with the given argument, instead of the general help.
      # Note that optplus does not allow options specific to actions so this is
      # just text.
      #
      # @param [String] action to describe with helpful text
      # @param [Array] lines of helpful text to display as arguments
      def help(action, *lines)
        @_help ||= Hash.new
        @_help[action] = lines
      end
      
      attr_accessor :_help
      
      # Do the option parsing and actioning stuff
      #
      # If you write an optplus class, run the script and nothing happens it is because
      # you forgot to add MyClass.run! Simple and easily done. 
      #
      def run!
        
        me = self.new(self)
        
        if me._needs_help? then
          me._help_me
        elsif me._args.length > 0 then
          action = me.next_argument
          alup = @_actions.abbrev(action)
          if alup.has_key?(action) then
            begin
              me.send(alup[action].to_sym)
              
              # trap a deliberate exit and tidy up
              # if required
            rescue ExitOnError
              me.after_actions if me.respond_to?(:after_actions)
              exit 1
            end
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
      
    end # class << self
    
    instance_eval do
      def nest_parser(name, klass, description)
        self.describe(name, description)
        self._help[name] = klass
        class_eval %Q{
          def #{name}
            #{klass}.run!(self)
          end
        }
      end
    end
    
    def initialize(klass)
      
      @klass = klass
      @klass._help ||= Hash.new
      @_help = false
      @options = Hash.new
      
      self.before_all if self.respond_to?(:before_all)
      
      begin
        @_optparse = OptionParser.new do |opts|
          @program_name = opts.program_name
          opts.banner = "Usage: #{@program_name} #{@klass._banner}"
          opts.separator ""
          
          @klass._description.each do |dline|
            opts.separator "  " + dline
          end
          
          opts.separator ""
          opts.separator "Actions:"
          opts.separator ""
          @klass._descriptions.each do |key, value|
            opts.separator "  #{key} - #{value}"
          end
          
          opts.separator ""
          opts.separator "Options:"
          opts.separator ""
          
          if @klass._help.length > 0 then
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
      
        # trap a deliberate exit and force exit before
        # executing before_actions
      rescue ExitOnError
        exit 1
      end
      
      self.before_actions if self.respond_to?(:before_actions)
      
    end
    
    attr_reader :program_name
    
    # add a switch for debug mode
    def debug_option(opts, switch='-D')
      opts.on_tail(switch, '--debug', 'show debug information') do |d|
        @options[:debug] = d
      end
    end
    
    # add a switch for verbose mode
    def verbose_option(opts, switch='-V')
      opts.on_tail(switch, '--verbose', 'show verbose information') do |v|
        @options[:verbose] = v
      end
    end     
  
    
    attr_reader :_args
    
    # return the next argument, if there is one
    # or nil otherwise
    def next_argument
      @_args.shift
    end
    
    # return all of the remaining args, or an empty array
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
    
    # set the value of the given option, which defaults to true
    def set_option(key, value=true)
      @options[key] = value
    end
    
    # get the value of the option
    def get_option(key)
      @options[key]
    end
    
    # check if the option has been set
    def option?(key)
      @options.has_key?(key)
    end
    
    # call this to exit the script in case of an error
    # and ensure any tidying up has been done
    def exit_on_error
      raise ExitOnError
    end
    
    def _help_me
      if _args.length > 0 then
        action = next_argument
        alup = @klass._actions.abbrev(action)
        action = alup[action].to_sym if alup.has_key?(action)
        if @klass._help.has_key?(action) then
          # valid help so use it
          if @klass._help[action].kind_of?(Array) then
            puts "Help for #{action}"
            puts ""
            @klass._help[action].each do |aline|
              puts aline
            end
            puts ""
          else
            @klass._help[action]._help_me
          end
          return
        elsif @klass._actions.include?(action)
          puts "Sorry, there is no specific help for action: #{action}".yellow
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

end
