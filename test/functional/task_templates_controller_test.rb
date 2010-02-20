require 'test_helper'

class TaskTemplatesControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  context 'a logged in user' do
    context 'when create new task template' do
      should 'create task template with given parameters' do
      end
      should 'not create any worklogs' do
      end
    end
    context 'when update task tamplate' do
      should 'change attributes' do
      end
      should 'change custom property values' do
      end
      should 'add todo' do
      end
      should 'remove todo' do
      end
      should 'add users' do
      end
      should 'remove users' do
      end
      should 'add client' do
      end
      should 'remove client' do
      end
      should 'add attachment' do
      end
      should 'remove attachment' do
      end
      should 'can not add any dependecies' do
      end
      should 'can not add any worklogs' do
      end
    end
    context 'when create task from given template' do
      context ', a created tasks' do
        should 'copy all attributes from tamplate' do
        end
        should 'copy all todos from template' do
        end
        should 'assing all users from template' do
        end
        should 'assing all clients from template' do
        end
        should 'copy all attachments from template' do
        end
        should 'assing all custom property values' do
        end
      end
      context ', the template' do
        should 'not change' do
        end
      end
    end
  end
end
