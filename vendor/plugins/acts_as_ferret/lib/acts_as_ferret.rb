# Copyright (c) 2006 Kasper Weibel Nielsen-Refs, Thomas Lockney, Jens Krämer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'multi_index'
require 'more_like_this'
require 'class_methods'
require 'instance_methods'

# 0.10 problems
# Ferret::Search::Similarity, Ferret::Search::Similarity.default missing
# IndexReader#latest? segfaults when used on multiple indexes
#

# The Rails ActiveRecord Ferret Mixin.
#
# This mixin adds full text search capabilities to any Rails model.
#
# The current version emerged from on the original acts_as_ferret plugin done by
# Kasper Weibel and a modified version done by Thomas Lockney, which  both can be 
# found on the Ferret Wiki: http://ferret.davebalmain.com/trac/wiki/FerretOnRails.
#
# basic usage:
# include the following in your model class (specifiying the fields you want to get indexed):
# acts_as_ferret :fields => [ 'title', 'description' ]
#
# now you can use ModelClass.find_by_contents(query) to find instances of your model
# whose indexed fields match a given query. All query terms are required by default, but 
# explicit OR queries are possible. This differs from the ferret default, but imho is the more
# often needed/expected behaviour (more query terms result in less results).
#
# Released under the MIT license.
#
# Authors: 
# Kasper Weibel Nielsen-Refs (original author)
# Jens Kraemer <jk@jkraemer.net> (active maintainer)
#
module FerretMixin
  module Acts #:nodoc:
    module ARFerret #:nodoc:

      # decorator that adds a total_hits accessor to search result arrays
      class SearchResults
        attr_reader :total_hits
        def initialize(results, total_hits)
          @results = results
          @total_hits = total_hits
        end
        def method_missing(symbol, *args, &block)
          @results.send(symbol, *args, &block)
        end
        def respond_to?(name)
          self.methods.include?(name) || @results.respond_to?(name)
        end
      end
      
      def self.ensure_directory(dir)
        FileUtils.mkdir_p dir unless File.directory? dir
      end
      
      # make sure the default index base dir exists. by default, all indexes are created
      # under RAILS_ROOT/index/RAILS_ENV
      def self.init_index_basedir
        index_base = "#{RAILS_ROOT}/index"
        ensure_directory index_base
        @@index_dir = "#{index_base}/#{RAILS_ENV}"
        ensure_directory @@index_dir
      end
      
      mattr_accessor :index_dir
      init_index_basedir
      
      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      
      
    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it
ActiveRecord::Base.class_eval do
  include FerretMixin::Acts::ARFerret
end


class Ferret::Index::MultiReader
  def latest?
    # TODO: Exception handling added to resolve ticket #6. 
    # It should be clarified wether this is a bug in Ferret
    # in which case a bug report should be posted on the Ferret Trac. 
    begin
      @sub_readers.each { |r| return false unless r.latest? }
    rescue
      return false
    end
    true
  end
end

# END acts_as_ferret.rb
