#  CONSIDER  split the patch in two for separate submissions

##################################################################
##  eek eek ook ook patch to add directives to RDocage

require 'rdoc/rdoc'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/lines'
require 'rdoc/markup/simple_markup/fragments'
require 'rdoc/markup/simple_markup/to_html'


def find_method_contents(file_info, modool, method)
  file_info.each do |top|
    if mod   = top.find_module_named(modool) and
      symbol = mod.find_local_symbol(method)
        return symbol.token_stream
    end
  end
  return nil
end

module RubyToken
  class Token
    def to_html
      html = CGI.escapeHTML(text)
      
      if text.size == 1 and '!@#$%^&*(){}?+/=[]\\|.,"\'<>-_;:'.include?(text)
        return "<strong>#{ html }</strong>"
      else
        return html
      end
    end
  end

  class TkCOMMENT;     def to_html; '<em style="color: #666; font-size: 110%">' + super + '</em>'    ; end; end
  class TkKW;          def to_html; '<span style="color: #990099">' + super + '</span>'  ; end; end
  class TkIDENTIFIER;  def to_html; '<span style="color: #003399">' + super + '</span>'  ; end; end
  class TkSYMBOL ;     def to_html; '<span style="color: #006600">' + super + '</span>'  ; end; end
  class TkOp;          def to_html; '<strong>' + super + '</strong>'  ; end; end
  class TkSTRING;      def to_html; '<span style="background-color: #ddffdd">' + super + '</span>'  ; end; end

#<RubyToken::TkASSIGN:0xb7870368 @text="=", @char_no=11, @line_no=346>
#<RubyToken::TkTRUE:0xb786ddac @text="true", @char_no=19, @line_no=347, @name="true">
#<RubyToken::TkCOMMA:0xb786db7c @text=",", @char_no=23, @line_no=347>
#<RubyToken::TkfLBRACK:0xb786d2d0 @text="[", @char_no=30, @line_no=347>
#<RubyToken::TkRBRACK:0xb786c8d0 @text="]", @char_no=39, @line_no=347>
#<RubyToken::TkFALSE:0xb7868488 @text="false", @char_no=19, @line_no=349, @name="false">
  
end

module SM

  class Line
    PURE_HTML = :PURE_HTML
    PURE_RUBY = :PURE_RUBY
    TRANSCLUDE = :TRANSCLUDE
  end

  class PureHTML < Fragment
    type_name Line::PURE_HTML
  end

  class PureRUBY < Fragment
    type_name Line::PURE_RUBY
  end

  class Transclude < Fragment
    type_name Line::TRANSCLUDE
  end

  class ToHtml
    def accept_transclude(am, fragment)
      if found = find_method_contents(@context.context.parent.in_files, *fragment.txt.split('#'))
        @res << '<pre style="background-color: white">'
        #  to do: hilite syntax; make method name clickable
        found.each_with_index do |tok, index|
          next if 0 == index and tok.text =~ /^\#/
          next if 1 == index and tok.text == "\n"
          @res << tok.to_html
        end
        @res << '</pre>'
      else
        raise "missing transclusion: #{ fragment.inspect }"
        @res << fragment.txt
      end
    end
    
    def accept_pure_html(am, fragment)
      @res << fragment.txt
    end
    
    def accept_pure_ruby(am, fragment)
      @res << eval(fragment.txt)
    end
  end

  class LineCollection  
    def accept(am, visitor)
      visitor.start_accepting

      @fragments.each do |fragment|
        case fragment
        when Verbatim
          visitor.accept_verbatim(am, fragment)
        when PureHTML
           visitor.accept_pure_html(am, fragment)
        when PureRUBY
           visitor.accept_pure_ruby(am, fragment)
        when Transclude
           visitor.accept_transclude(am, fragment)
        when Rule
          visitor.accept_rule(am, fragment)
        when ListStart
          visitor.accept_list_start(am, fragment)
        when ListEnd
          visitor.accept_list_end(am, fragment)
        when ListItem
          visitor.accept_list_item(am, fragment)
        when BlankLine
          visitor.accept_blank_line(am, fragment)
        when Heading
          visitor.accept_heading(am, fragment)
        when Paragraph
          visitor.accept_paragraph(am, fragment)
        end
      end

      visitor.end_accepting
    end
  
  end
  
  class SimpleMarkup
  private
  
    def assign_types_to_lines(margin = 0, level = 0)

      while line = @lines.next
      
        if /^\s*%html/ === line.text then
          line.text.sub!("%html","")
          line.stamp( Line::PURE_HTML, level )
          next
        end
      
        if /^\s*%transclude/ === line.text then
          line.text.sub!("%transclude","")
          line.stamp( Line::TRANSCLUDE, level )
          next
        end
      
        if /^\s*%ruby/ === line.text then
          line.text.sub!("%ruby","")
          line.stamp( Line::PURE_RUBY, level )
          next
        end
      
        if line.isBlank?
          line.stamp(Line::BLANK, level)
          next
        end
        
        # if a line contains non-blanks before the margin, then it must belong
        # to an outer level

        text = line.text
        
        for i in 0...margin
          if text[i] != SPACE
            @lines.unget
            return
          end
        end

        active_line = text[margin..-1]

        # Rules (horizontal lines) look like
        #
        #  ---   (three or more hyphens)
        #
        # The more hyphens, the thicker the rule
        #

        if /^(---+)\s*$/ =~ active_line
          line.stamp(Line::RULE, level, $1.length-2)
          next
        end

        # Then look for list entries. First the ones that have to have
        # text following them (* xxx, - xxx, and dd. xxx)

        if SIMPLE_LIST_RE =~ active_line

          offset = margin + $1.length
          prefix = $2
          prefix_length = prefix.length

          flag = case prefix
                 when "*","-" then ListBase::BULLET
                 when /^\d/   then ListBase::NUMBER
                 when /^[A-Z]/ then ListBase::UPPERALPHA
                 when /^[a-z]/ then ListBase::LOWERALPHA
                 else raise "Invalid List Type: #{self.inspect}"
                 end

          line.stamp(Line::LIST, level+1, prefix, flag)
          text[margin, prefix_length] = " " * prefix_length
          assign_types_to_lines(offset, level + 1)
          next
        end


        if LABEL_LIST_RE =~ active_line
          offset = margin + $1.length
          prefix = $2
          prefix_length = prefix.length

          next if handled_labeled_list(line, level, margin, offset, prefix)
        end

        # Headings look like
        # = Main heading
        # == Second level
        # === Third
        #
        # Headings reset the level to 0

        if active_line[0] == ?= and active_line =~ /^(=+)\s*(.*)/
          prefix_length = $1.length
          prefix_length = 6 if prefix_length > 6
          line.stamp(Line::HEADING, 0, prefix_length)
          line.strip_leading(margin + prefix_length)
          next
        end
        
        # If the character's a space, then we have verbatim text,
        # otherwise 

        if active_line[0] == SPACE
          line.strip_leading(margin) if margin > 0
          line.stamp(Line::VERBATIM, level)
        else
          line.stamp(Line::PARAGRAPH, level)
        end
      end
    end
  end
end

##  eek eek ook ook patch to add directives to RDocage
##################################################################
