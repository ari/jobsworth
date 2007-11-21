module ShoutHelper
  def format_message(m)
    m.gsub(/\n/,'<br />')
    m = Juggernaut.html_escape(m)

    wrap_text(m)

  end

end
