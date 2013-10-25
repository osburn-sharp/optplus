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
require 'colored'

module Optplus
  
  # bunch of convenience methods to output messages and get inputs for
  # command-line scripts
  module IO
    
    # lookup to map between symbols and responses
    Answers = Hash.new(false).merge({:no=>'n', :yes=>'y', :skip=>'s', :diff=>'d', :list=>'l'})
    
    def say(txt)
      puts txt
    end
    
    def say_ok(txt)
      puts txt.green
    end
    
    def warn(txt)
      puts txt.yellow
    end
    
    def alert(txt)
      puts txt.red.bold
    end
    
    def ask(question, default=:no, answers=nil)
      answers ||= Answers
      default = answers.keys.first unless answers.has_key?(default)
      def_key = answers[default]
      answer_options = answers.values.collect {|k| k == def_key ? k.upcase : k}.join('')
      loop do
        print "#{question}(#{answer_options})? "
        response = $stdin.gets[0,1].downcase
        if response == '?' then
          answers.each_pair do |key, val|
            puts "#{key}"
          end
          next
        end
        if answers.has_value?(response) then
          return answers.key(response)
        else
          return default
        end
      end
      
    end
    
    def continue?(question, default=false)
      def_response = default ? :yes : :no
      response = ask(question, def_response, {:yes=>'y', :no=>'n'})
      return response == :yes
    end
    
  end
end
