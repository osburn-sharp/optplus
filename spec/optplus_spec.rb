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


require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'optplus/config'
require 'optplus/errors'
require 'jellog'

conf_file = File.expand_path(File.dirname(__FILE__) + '/../test/conf.d/optplus.rb')

describe Optplus do

  before(:all) do
    @params = Optplus::Config.new(conf_file)
    Jellog::Logger.disable_syslog
  end

  before(:each) do
    @optplus = Optplus::Service.new("Testkey", @params)
  end

  after(:each) do
    @optplus.stop_callback("Testkey")
  end


  it "should do what you want" do
    pending "Need to do something here"
  end

end
