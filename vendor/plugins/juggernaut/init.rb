# Include hook code here

require "juggernaut"
ActionController::Base.send :include, Juggernaut

#ActionView::Base::load_helpers 
