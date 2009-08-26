module SearchHelper
  def format_message(m)
    m = Juggernaut.html_escape(m)
    m.gsub!(/\n/,'<br />')
    m.gsub!(/\r/,'')

    wrap_text(m, 300)
  end
end
