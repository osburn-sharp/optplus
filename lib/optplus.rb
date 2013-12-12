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
      
      # Adds a description to the help/usage
      #
      # This takes any number of string arguments and displays them as separate lines.
      #
      # @param [Array] lines of description text as variable arguments
      def description(*lines)
        @_description = lines
      end
      
      
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
      
      # @!visibility private
      attr_reader :_banner
      # @!visibility private
      attr_reader :_description
      # @!visibility private
      attr_reader :_actions
      # @!visibility private
      attr_reader :_descriptions
      # @!visibility private
      attr_accessor :_help
      # end of private stuff
      
      # @!visibility public
      
      # Do the option parsing and actioning stuff
      #
      # If you write an optplus class, run the script and nothing happens it is because
      # you forgot to add MyClass.run! Simple and easily done. 
      #
      def run!
        
        @_parent ||= nil
        @_help ||= Hash.new
        
        begin
          me = self.new
          
          if me._needs_help? then
            me._help_me
          elsif me._args.length > 0 then
            action = me.next_argument
            alup = @_actions.abbrev(action)
            if alup.has_key?(action) then
  
              me.before_actions if me.respond_to?(:before_actions)
              
              begin
                me.send(alup[action].to_sym)
                
                # trap a deliberate exit and tidy up
                # if required
              rescue Optplus::ExitOnError => err
                puts err.message.red.bold unless err.message == ''
                me.after_actions if me.respond_to?(:after_actions)
                raise Optplus::ExitOnError, '' # with no message
              end
              
              me.after_actions if me.respond_to?(:after_actions)
              
            else
              puts "Sorry, What?"
              puts ""
              me._get_help
            end
          else
            me._get_help
          end
          
          return true
          
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
        rescue Optplus::ParseError => err
          puts "Error: #{err.message}".red.bold
        rescue Optplus::ExitOnError => err
          puts err.message.red.bold unless err.message == ''
          raise Optplus::ExitOnError, '' unless @_parent.nil?
        end
        
        # only rescued exceptions will reach here
        exit 1 if @_parent.nil?
        
      end
        
    end # class << self
    
    # @!method self.nest_parser(name, klass, description)
    #  nest a parser for subcommands
    #  This will add the given name to the actions list
    #  and then parse the next argument as a subcommand
    #  The klass must inherit {Optplus::NestedParser}
    #  @param [Symbol] name of action to nest
    #  @param [Class] klass of Nested Parser
    #  @param [String] description of action
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
    
    # create an Optplus instance, define the options and parse the command line
    #
    # This method will call the following if they have been defined:
    #
    # * before_all - any setting up needed right at the start
    # * options - to add options
    # * before_actions - after options have been parsed but before actions are
    #   implemented
    #
    # @param [Class] klass for internal use in the instance itself
    def initialize
      
      @klass = self.class
      @klass._help ||= Hash.new
      @_help = false
      @_man = false
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
          flags = 0
          @klass._descriptions.each do |key, value|
            flag = @klass._help.has_key?(key.to_sym) ? '(-h)' : ''
            flags += 1 unless flag == ''
            opts.separator "  #{key} - #{value} #{flag}"
          end
          
          if flags > 0 then
            opts.separator ""
            opts.separator "  (-h indicates actions with additional help)"
            opts.separator ""
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
          
          opts.on_tail('--man', 'output man-like help') do
            @_help = true
            @_man = true
          end
          
        end
  
        @_args = @_optparse.permute(ARGV)
      
        # trap a deliberate exit and force exit before
        # executing before_actions
      rescue ExitOnError => err
        puts err.message.red.bold unless err.message == ''
        exit 1
      end
      
      
    end
    
    # provides convenient access to the name of the program
    attr_reader :program_name
    
    # add optparse option for debug mode
    #
    # @param [Optparse] opts being the optparse instance
    # @param [String] switch being the short-form option on the command line
    def debug_option(opts, switch='-D')
      opts.on_tail(switch, '--debug', 'show debug information') do |d|
        @options[:debug] = d
      end
    end
    
    # add optparse option for verbose mode
    #
    # @param [Optparse] opts being the optparse instance
    # @param [String] switch being the short-form option on the command line
    def verbose_option(opts, switch='-V')
      opts.on_tail(switch, '--verbose', 'show verbose information') do |v|
        @options[:verbose] = v
      end
    end     
  

    # @!visibility private
    attr_reader :_args

    
    # return the next argument, if there is one or nil otherwise
    #
    # @return [String] being the next argument
    def next_argument
      @_args.shift
    end
    
    # return the next argument or the given default
    #
    # @param [Object] default to return if no argument
    # @return [String] being the next argument or the default
    def next_argument_or(default)
      next_argument || default
    end
    
    # return the next argument or raise exception with the given message
    #
    # The exception does not need to be handled because {Optplus::Parser.run!}
    # will rescue it and display an error message.
    #
    # @param [String] msg to attach to exception
    # @return [String] being the next argument
    # @raise [Optplus::ParseError] if there is no argument
    def next_argument_or_error(msg)
      next_argument || raise(Optplus::ParseError, msg)
    end
    
    # return all of the remaining args, or an empty array
    #
    # This clears all remaining arguments so that subsequent
    # calls e.g. to {Optplus::Parser#next_argument} return nil
    #
    # @return [Array] of arguments
    def all_arguments
      args = @_args.dup
      @_args = Array.new
      return args
    end
    
    
    # @!visibility private
    def _get_help(indent=0)
      prefix = " " * indent
      @_optparse.help.split("/n").each do |line|
        puts prefix + line
      end
      puts ""
    end
    
    # @!visibility private
    def _needs_help?
      @_help
    end
    
    # set the value of the given option, which defaults to true
    #
    # If a value is omitted then the option is set to be true
    #
    # @param [Symbol] key to use in getting the option
    # @param [Object] value to set the option to
    def set_option(key, value=true)
      @options[key] = value
    end
    
    # get the value of the option
    #
    # Returns nil if there is no option with the given key
    #
    # @param [Symbol] key to the option to get
    # @return [Object] or nil if no option set
    def get_option(key)
      @options[key]
    end
    
    # check if the option has been set
    #
    # @param [Symbol] key for the option to test
    # @return [Boolean] true if option has been set
    def option?(key)
      @options.has_key?(key)
    end
    
    # call this to exit the script in case of an error
    # and ensure any tidying up has been done
    def exit_on_error(msg='')
      raise Optplus::ExitOnError, msg
    end
    
    # @!visibility private
    def _help_me
      if @_man then
        self.man
        return
      end
      # is there an action on the line?
      if _args.length > 0 then
        # yes, but is it legit?
        action = next_argument
        alup = @klass._actions.abbrev(action)
        action = alup[action].to_sym if alup.has_key?(action)
        if @klass._help.has_key?(action) then
          # valid help so use it
          if @klass._help[action].kind_of?(Array) then
            # its an array of strings, so print them
            puts "Help for #{action}"
            puts ""
            @klass._help[action].each do |aline|
              puts aline
            end
            puts ""
          else
            # its a nested parser so call its _help_me method
            nested_klass = @klass._help[action]
            nested_parser = nested_klass.new(self)
            nested_parser._help_me
          end
          return
        elsif @klass._actions.include?(action.to_s)
          # valid action but no help
          puts "Sorry, there is no specific help for action: #{action}".yellow
          puts ""
        else
          # invalid action
          puts "Sorry, but I do not understand the action: #{action}".red.bold
          puts ""
        end
      end
      _get_help
      
    end
    
    # output all the help in one go!
    def man
      puts "Help Manual for #{@program_name}"
      puts ""
      _get_help
      @klass._help.each_pair do |action, help|
        puts "Action: #{action}:"
        puts ""
        if help.kind_of?(Array) then
          help.each do |hline|
            puts "  " + hline
          end
        else

          np = help.new(self)
          np._get_help(2)
          puts ""
          
          help._help.each_pair do |subaction, subhelp|
            puts "  Subaction: #{subaction}"
            puts ""
            subhelp.each do |hline|
              puts "    " + hline
            end
            puts ""
          end
        end
        puts " "
      end
      puts ""
    end #man
    
  end

end
