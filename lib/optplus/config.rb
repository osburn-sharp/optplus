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


require 'jerbil/jerbil_service/config'

module Optplus
  
  
  # This class defines the params that are required by {Optplus::Base}
  # The parameters are defined using Jeckyl conventions and are in addition to those
  # inherited from the JerbilService base class.
  #
  # Full details of each parameter are provided separately
  #
  # @see file:lib/optplus/config.md
  #
  class Config < JerbilService::Config
    
    #define your parameters here
    def configure_a_parameter(val)
      
    end
    
  end
  
end
