class ScoreRule < ActiveRecord::Base
  attr_accessible(:name, :score, :score_type, :exponent)
end
