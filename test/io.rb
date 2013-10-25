#!/usr/bin/env ruby
#
#
#
# = Test IO
#
# == Optplus
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

require 'optplus/IO'

include Optplus::IO

say "hello"

say_ok "That's OK"

warn "This is getting tricky"

alert "Too late!"

if ask("Overwrite?") == :yes then
  warn "Overwriting"
else
  alert "You really should have"
end

if continue?("Do you want to continue?") then
  say_ok "Continuing"
else
  warn "Not continuing"
end

if continue?("Do you want to stop?", true) then
  say_ok "Stopped"
else
  warn "Not stopping"
end

colour = ask("What colour?", :red, {red:'r', green:'g', blue:'b'})

say "You chose #{colour.to_s}"
  