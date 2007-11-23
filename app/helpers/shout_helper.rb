module ShoutHelper
  def format_message(m)
    if m.count("\n") > 0
      # Multi-line paste
      m = "<pre><code>#{Juggernaut.html_escape(m)}</code></pre>"
    else
      m = Juggernaut.html_escape(m)
    end
    m.gsub!(/\n/,'<br />')
    m.gsub!(/\r/,'')

    wrap_text(m, 300)
  end

end
