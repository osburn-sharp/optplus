#!/usr/bin/env ruby
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


require 'optplus'


class MyParser < OptPlus
  
  usage "[options] action"
    
  description "A simple test",
    "that tells you little"
    
  def before_all
    set_option :env, :dev
  end


  # define the options for this command
  def options(opts)
    opts.on('-a', '--all', 'show me everything') do
      set_option :all
    end
    opts.on('-A', '--altogether', 'show me everything, really') do
      set_option :altogether
    end
    opts.on('-e', '--environment TYPE', [:dev, :dec, :test, :prod], 'specify the environment') do |env|
      set_option :env, env
    end
    opts.on('-s', '--sob [String]', String, 'sob when telling truth') do |cry|
      set_option :sob, cry
    end
    
    debug_option(opts)
  end
  
  # define things that need to be done before any actions
  def before_actions
    @secrets = ['The answer to the universe is 42',
      'The mystery man is Blake',
      'The beginning of the Universe is the wrong question'
    ]
  end
  
  describe :show, "Show me what you know"
  def show
    unless get_option :all
      puts "I know nothing"
    else
      puts "OK I will tell you everything"
      puts get_option :sob if option? :sob
      puts "You're in: #{get_option :env}"
      @secrets.each do |secret|
        puts secret
      end
      puts get_option :sob if option? :sob
    end
  end
  help :show, "You can use this to find out what I know",
    "If you persist with options I may tell you more"
  
  describe :about, "Tell me about something"
  def about
    subject = all_arguments.join(' ')
    if subject then
      puts "I know nothing about #{subject}"
    else
      puts "Sorry, what do you want to know about?"
    end
  end
  
  describe :sheep, "All about sheep"
  def sheep
    puts "Baaaa"
  end
  
end

MyParser.run!