# encoding: UTF-8
# A tag belonging to a company and task

class Tag < ActiveRecord::Base

  belongs_to :company
  has_and_belongs_to_many :tasks, :join_table => :task_tags, :class_name => "TaskRecord", :association_foreign_key => "task_id"

  validates :name, :presence => true, :uniqueness => { :scope => [:company_id] }

  def count
    tasks.where("tasks.completed_at IS NULL").count
  end

  def total_count
    tasks.count
  end

  # to_s must always return an String, even if +name+ is nil.
  def to_s
    self.name.to_s
  end

  # Returns an array of tag counts grouped by name for the given company
  # All tags are retured by default - include task_conditions if you
  # need to restrict those counts
  def self.top_counts(company, task_conditions = nil)
    top_counts_as_tags(company).map { |tag, count| [ tag.name, count ] }
  end

  # Returns an array of tag counts grouped by tag.
  # Uses Tag.top_counts.
  def self.top_counts_as_tags(company, task_conditions = nil)
    sql = <<-EOS
          select tag_id, count(task_tags.task_id)
          from task_tags
          left join
          tasks on task_tags.task_id = tasks.id
          left join
          task_users on task_tags.task_id = task_users.task_id
          #{ task_conditions ? "where #{ task_conditions }" : "" }
          group by tag_id
    EOS
    ids_and_counts = connection.select_rows(sql)

    res = ids_and_counts.map do |id, count|
      [ company.tags.detect { |t| t.id == id.to_i }, count.to_i ]
      end.reject{ |tag, count| tag.nil? }

    return res.sort_by { |tag, count| tag.name.downcase }
  end

end






# == Schema Information
#
# Table name: tags
#
#  id         :integer(4)      not null, primary key
#  company_id :integer(4)
#  name       :string(255)
#
# Indexes
#
#  index_tags_on_company_id_and_name  (company_id,name)
#

