module JavascriptHelper
  # Sets up elements matching selector to select all their text  
  # when they receive focus
  def select_on_focus(selector)
    js = <<-EOS
      jQuery("#{ selector }").focus(function(elem) {
        elem.target.select();
      });
    EOS

    return javascript_tag(js, :defer => "defer")
  end
end
