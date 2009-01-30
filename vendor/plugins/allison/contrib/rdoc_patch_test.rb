#:stopdoc:
require 'rdoc/rdoc'
require 'test/unit'
require 'fileutils'
#:startdoc:

MY_ROOT = File.dirname(__FILE__)
require MY_ROOT + '/../doc/rdoc_patch'
require MY_ROOT + '/../lib/assert_xpath'  #  assert_xpath vs RDoc!!!


def doc(thing)
    puts (thing.public_methods - self.public_methods).sort()
end


class String
  def blank?
    return strip.size == 0
  end
end

#:stopdoc:
  #  ERGO  shouldn't %HTML be :html: ?
#:startdoc:

class RDocMonkeyPatchTest < Test::Unit::TestCase
  include AssertXPath

  def publish(file_1_contents, file_2_contents)
    rdoc = RDoc::RDoc.new
    args = ['scratch_1.rb', 'scratch_2.rb', '-oscratch', '--quiet']
    File.open(args[0], 'w'){|f|  f.write file_1_contents  }
    File.open(args[1], 'w'){|f|  f.write file_2_contents  }
    rdoc.document(args)
  end
 
  def test_rdoc_raw_ruby
    publish("
             class Foo
               # %ruby 'in the zone'
               def daddys_got_them_debellum_blues
               end
             end", '')
          
    assert_xml File.read('scratch/classes/Foo.html')
    assert_tag_id :div, 'method-M000003' do  #  CONSIDER: why 003 ?
      assert_xpath 'div[ "method-description" = @class ]' do |div|
        assert_match 'in the zone', div.inner_text
      end
    end
  end
  
  def test_rdoc_crosspatch
    publish("
             class Foo
               # exemplary
               def i_think_were_alone_now
                 # payload
               end
              end
             ", "
             class Bar
               # See Foo#i_think_were_alone_now
               # %transclude Foo#i_think_were_alone_now
               def sugar_minot
               end
             end
             ")

    assert_xml File.read('scratch/classes/Foo.html')

    assert_tag_id :div, 'method-M000001' do
      assert_xpath 'div[ "method-description" = @class ]' do |div|
        assert_match 'exemplary', div.inner_text
      end
    end
    
    assert_xml File.read('scratch/classes/Bar.html')
    
    assert_tag_id :div, 'method-M000002' do
      assert_xpath 'div[ "method-description" = @class ]' do |div|
        assert_match 'i_think_were_alone_now', div.inner_text
        assert_match 'payload', div.inner_text
      end
    end
  end
  
  def teardown
    FileUtils.rm_rf('scratch')   rescue nil
    File.unlink('scratch_1.rb')  rescue nil
    File.unlink('scratch_2.rb')  rescue nil
  end
end

