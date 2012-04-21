class ScoreRule < ActiveRecord::Base
  include ScoreRuleTypes

  attr_accessible :name, :score, :score_type, :exponent
  attr_accessor   :final_value

  belongs_to :controlled_by, 
             :polymorphic => true

  validates :exponent,
            :presence => true

  validates :name, 
            :presence => true,
            :length   => { :maximum => 30 }

  validates :score, 
            :presence     => true, 
            :numericality => true

  validates :score_type,
            :presence  => true,
            :inclusion => { :in => ScoreRuleTypes::all_score_types }
  

  def calculate_score_for(task)
    case score_type
      when FIXED then 
        result            = score
        self.final_value  = "#{result.to_i}"
        result
      when TASK_AGE then 
        task_age          = get_task_age_for(task)
        result            = calculate(score, task_age, exponent)
        self.final_value  = "#{score} x (#{task_age} ^ #{exponent}) = #{result}"
        result
      when LAST_COMMENT_AGE then
        last_comment_age  = get_last_comment_age_for(task)
        result            = calculate(score, last_comment_age, exponent)
        self.final_value  = "#{score} x (#{last_comment_age} ^ #{exponent}) = #{result}"
        result
      when OVERDUE then
        pass_due_age        = get_pass_due_age_for(task)
        result              = calculate(score, pass_due_age, exponent)
        self.final_value    = "#{score} x (#{pass_due_age} ^ #{exponent}) = #{result}"
        result
    end
  end

  private 

  def get_task_age_for(task)
    # If the task is brand new 'created_at' should be nil, this code sets
    # a default value for it.
    task_created_at = (task.created_at.nil?) ? Time.now.utc : task.created_at
    (Time.now.utc.to_date - task_created_at.to_date).to_f
  end

  def get_last_comment_age_for(task)
    # Set last_comment_started to a default value (in case the task doesn't 
    # have comments)
    last_comment_started_at = Time.now.utc
    # Return all the public comments (work logs of type 'comment' and that belong to
    # one of the customers of the task)
    public_comments = Task.public_comments_for(task)

    if public_comments.any? and not public_comments.first.started_at.nil?
      last_comment_started_at = public_comments.first.started_at
    end
    (Time.now.utc.to_date - last_comment_started_at.to_date).to_f
  end

  def get_pass_due_age_for(task)
    target_date = (task.target_date || Time.now.utc).to_date
    (Time.now.utc.to_date - target_date).to_f 
  end

  def calculate(score, value, exp)
    result = score * ( value.abs ** exp)
    result = -result if value < 0 
    result.to_i
  end
end


# == Schema Information
#
# Table name: score_rules
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  score              :integer(4)
#  score_type         :integer(4)
#  exponent           :decimal(5, 2)   default(1.0)
#  controlled_by_id   :integer(4)
#  controlled_by_type :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#
# Indexes
#
#  index_score_rules_on_controlled_by_id  (controlled_by_id)
#  index_score_rules_on_score_type        (score_type)
#

