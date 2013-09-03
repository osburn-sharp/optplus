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

# This file groups together all the errors for optplus.
# Preceed each class with a description of the error

module Optplus

  # A general class for all errors created by this project. All specific exceptions
  # should be children of this class
  class OptplusError < RuntimeError; end
  
  # add specific errors as required
  
  # description
  class ParseError < OptplusError; end
  class ExitOnError < OptplusError; end

end
