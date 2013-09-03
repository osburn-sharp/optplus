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

  class NestedParser < Optplus::Parser
    
    class << self
      def run!(parent)
        @_parent = parent
        super()
      end
      
      attr_reader :_parent
    
      def _help_me
        prog_name = File.basename($0, File.extname($0))
        puts "Usage: #{prog_name} #{self._banner}"
        puts ""
        self._description.each do |line|
          puts line
        end
        puts ""
        self._descriptions.each_pair do |action, description|
          puts "  #{action} - #{description}"
        end
        puts ""
        puts "For full details of options etc:"
        puts "  #{prog_name} -h"
      end
      
    end # class << self
    
    def initialize(klass)
      @klass = klass
      @_parent = @klass._parent
      self.before_all if self.respond_to?(:before_all)
      self.before_actions if self.respond_to?(:before_actions)
    end
    
    def _parent
      @_parent
    end
    
    def _args
      _parent._args
    end
    
    def next_argument
      _parent.next_argument
    end
    
    def all_arguments
      _parent.all_arguments
    end
    
    def get_option(key)
      _parent.get_option(key)
    end
    
    def option?(key)
      _parent.option?(key)
    end
    
    # def _get_help
    #   _parent._get_help
    # end
    

    
  end
  
end