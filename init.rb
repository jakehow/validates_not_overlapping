$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'validates_not_overlapping'
ActiveRecord::Base.send :extend, ValidatesNotOverlapping