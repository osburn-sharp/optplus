#
#
# = Next Parser
#
# == SubTitle
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
#
require 'optplus'

module Optplus
  
  # define a nested parser to add sub-actions to an action
  #
  # Useful if you want to group actions together. For example,
  # if you have a command that does things for services (for example)
  # and other things for servers (for example) then you can define
  # a nested parser for each and then define actions 'services' and 'servers'
  # that use these parsers:
  #
  #    my_command servers list --all
  #    my_command services list --all
  #
  # Optplus does not allow option switches to be specific to any one action -
  # its an everything and everywhere approach.
  #
  # Note that NestedParser inherits everything from Parser and could therefore 
  # nest another parser within itself, ad infinitum. You could also define
  # methods such as #options which would be a waste because they would never 
  # be called.
  #
  class NestedParser < Optplus::Parser
    
    class << self
      
      # @!visibility private
      def run!(parent)
        # set class attribute so that the instance
        # can determine its parent class
        @_parent = parent
        super()
      end
      
      # @!visibility private
      attr_reader :_parent
      
      #@!visibility private
      # def _help_me
      #   prog_name = File.basename($0, File.extname($0))
      #   puts "Usage: #{prog_name} #{self._banner}"
      #   puts ""
      #   self._description.each do |line|
      #     puts line
      #   end
      #   puts ""
      #   self._descriptions.each_pair do |action, description|
      #     puts "  #{action} - #{description}"
      #   end
      #   puts ""
      #   puts "For full details of options etc:"
      #   puts "  #{prog_name} -h"
      # end
      
    end # class << self
    
    # @!visibility private
    def initialize(parent=nil)
      @klass = self.class
      @_parent = parent || @klass._parent
      self.before_all if self.respond_to?(:before_all)
      #self.before_actions if self.respond_to?(:before_actions)
    end
    
    # @!visibility private
    def _parent
      @_parent
    end
    
    # @!visibility private
    def _args
      _parent._args
    end
    
    # return the next argument, if there is one or nil otherwise
    # @see Optplus::Parser#next_argument
    def next_argument
      _parent.next_argument
    end
    
    # return the next argument or the given default
    # @see Optplus::Parser#next_argument
    def next_argument_or(default)
      _parent.next_argument_or(default)
    end
    
    #  return the next argument or raise exception with the given message
    # @see Optplus::Parser#next_argument
    def next_argument_or_error(message)
      _parent.next_argument_or_error(message)
    end
    
    # return all of the remaining args, or an empty array
    # @see Optplus::Parser#next_argument
    def all_arguments
      _parent.all_arguments
    end
    
    # get the value of the option
    # @see Optplus::Parser#next_argument
    def get_option(key)
      _parent.get_option(key)
    end
    
    #  check if the option has been set
    # @see Optplus::Parser#next_argument
    def option?(key)
      _parent.option?(key)
    end
    
    # @!visibility private
    def _get_help
      prog_name = File.basename($0, File.extname($0))
      puts "Usage: #{prog_name} #{self.class._banner}"
      puts ""
      self.class._description.each do |line|
        puts line
      end
      puts ""
      flags = 0
      self.class._descriptions.each_pair do |action, description|
        flag = @klass._help && @klass._help.has_key?(action.to_sym) ? '(-h)' : ''
        flags += 1 unless flag == ''
        puts "  #{action} - #{description} #{flag}"
      end
          
      if flags > 0 then
        puts ""
        puts "  (-h indicates actions with additional help)"
        puts ""
      end
            
      puts ""
      puts "For full details of options etc:"
      puts "  #{prog_name} -h"
    end

    
  end
  
end