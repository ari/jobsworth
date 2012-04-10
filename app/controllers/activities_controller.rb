# encoding: UTF-8
# Show recent activities

class ActivitiesController < ApplicationController
  # Show the overview page including whatever widgets the user has added.
  def index
    @columns = []
    current_user.widgets.each do |w|
      @columns[w.column] ||= []
      @columns[w.column] << w
    end
  end
end
