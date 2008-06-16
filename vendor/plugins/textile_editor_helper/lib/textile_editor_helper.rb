module TextileEditorHelper
  # creates a text_area for the given object/field pair
  # and keeps track of the ID used (necessary for textile_editor_initialize)
  def textile_editor(object, field, options={})
    editor_id = options[:id] || '%s_%s' % [object, field]
    mode      = options.delete(:simple) ? 'simple' : 'extended'
    (@textile_editor_ids ||= []) << [editor_id, mode]
    text_area(object, field, options)
  end
  
  def textile_editor_support
    output = []
    output << stylesheet_link_tag('textile-editor') 
    output << javascript_include_tag('textile-editor')
    output.join("\n")
  end
  
  def textile_editor_options(options={})
    (@textile_editor_options ||= { :framework => :prototype }).merge! options
  end
  
  # adds the necessary javascript include tags, stylesheet tags,
  # and load event with necessary javascript to active textile editor(s)
  # sample output:
  #    <link href="/stylesheets/textile-editor.css" media="screen" rel="Stylesheet" type="text/css" />
  #    <script src="/javascripts/textile-editor.js" type="text/javascript"></script>
  #    <script type="text/javascript">
  #    Event.observe(window, 'load', function() {
  #    TextileEditor.initialize('article_body', 'extended');
  #    TextileEditor.initialize('article_body_excerpt', 'simple');
  #    });
  #    </script>  
  # 
  # Note: in the case of this helper being called via AJAX, the output will be reduced:
  #    <script type="text/javascript">
  #    TextileEditor.initialize('article_body', 'extended');
  #    TextileEditor.initialize('article_body_excerpt', 'simple');
  #    </script>  
  # 
  # This means that the support files must be loaded outside of the AJAX request, either
  # via a call to this helper or the textile_editor_support() helper
  def textile_editor_initialize(*dom_ids)
    options = textile_editor_options.dup
    
    # extract options from last argument if it's a hash
    if dom_ids.last.is_a?(Hash)
      hash = dom_ids.last.dup
      options.merge! hash
      dom_ids.last.delete :framework
    end
    
    editor_ids = (@textile_editor_ids || []) + textile_extract_dom_ids(*dom_ids)
    editor_buttons = (@textile_editor_buttons || [])
    output = []
    output << textile_editor_support unless request.xhr?
    output << '<script type="text/javascript">'
    
    if !request.xhr?
      case options[:framework]
      when :prototype
        output << %{Event.observe(window, 'load', function() \{}
      when :jquery
        output << %{$(function() \{}
      end
    end      
    
    # output << %q{TextileEditor.framework = '%s';} % options[:framework].to_s
    output << editor_buttons.join("\n") if editor_buttons.any?
    editor_ids.each do |editor_id, mode|
      output << %q{TextileEditor.initialize('%s', '%s');} % [editor_id, mode || 'extended']
    end
    output << '});' unless request.xhr?
    output << '</script>'
    output.join("\n")
  end

  # registers a new button for the Textile Editor toolbar
  # Parameters:
  #   * +text+: text to display (contents of button tag, so HTML is valid as well)
  #   * +options+: options Hash as supported by +content_tag+ helper in Rails
  # 
  # Example:
  #   The following example adds a button labeled 'Greeting' which triggers an
  #   alert:
  # 
  #   <% textile_editor_button 'Greeting', :onclick => "alert('Hello!')" %> 
  #
  # *Note*: this method must be called before +textile_editor_initialize+
  def textile_editor_button(text, options={})
    return textile_editor_button_separator  if text == :separator
    button = content_tag(:button, text, options)
    button = "TextileEditor.buttons.push(\"%s\");" % escape_javascript(button)
    (@textile_editor_buttons ||= []) << button
  end
  
  def textile_editor_button_separator(options={})
    button = "TextileEditor.buttons.push(new TextileEditorButtonSeparator('%s'));" % (options[:simple] || '')
    (@textile_editor_buttons ||= []) << button
  end

  def textile_extract_dom_ids(*dom_ids)
    hash = dom_ids.last.is_a?(Hash) ? dom_ids.pop : {}
    hash.inject(dom_ids) do |ids, (object, fields)|
      ids + Array(fields).map { |field| "%s_%s" % [object, field] }
    end
  end
end