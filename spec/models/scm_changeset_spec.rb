require 'spec_helper'
GITHUB_PAYLOAD =<<-GITHUB
         {
         "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
           "repository": {
           "url": "http://github.com/defunkt/github",
           "name": "github",
           "description": "You're lookin' at it.",
           "watchers": 5,
           "forks": 2,
           "private": 1,
           "owner": {
           "email": "chris@ozmm.org",
           "name": "defunkt"
           }
         },
         "commits": [
           {
           "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
           "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
           "author": {
             "email": "chris@ozmm.org",
             "name": "Chris Wanstrath"
             },
           "message": "okay i give in",
           "timestamp": "2008-02-15T14:57:17-08:00",
            "added": ["filepath.rb"],
            "deleted" : ["filepath.html"],
            "modified" : ["README"]
           },
           {
           "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
           "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
           "author": {
             "email": "chris@ozmm.org",
             "name": "Chris Wanstrath"
           },
           "modified": ["fileone.rb", "filetwo.rb"],
           "deleted" : ["badfile.rb"],
           "added" : ["brandnewfile.txt"],
           "message": "update pricing a tad",
           "timestamp": "2008-02-15T14:36:34-08:00"
           }
         ],
         "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
         "ref": "refs/heads/master"
        }
        GITHUB

GOOGLE_PAYLOAD=  <<-GOOGLE
 {
   "project_name": "atlas-build-tool",
   "repository_path": "http://atlas-build-tool.googlecode.com/svn/",
   "revision_count": 1,
   "revisions": [
     { "revision": 33,
       "url": "http://atlas-build-tool.googlecode.com/svn-history/r33/",
       "author": "mparent61",
       "timestamp":   1229470699,
       "message": "working on easy_install",
       "path_count": 4,
       "added": ["/trunk/atlas_main.py"],
       "modified": ["/trunk/Makefile", "/trunk/constants.py"],
       "removed": ["/trunk/atlas.py"]
     }
   ]
 }
     GOOGLE

describe ScmChangeset do
  before(:each) do
    @scm_project=ScmProject.make
    @valid_attributes = {
      :author => 'user',
      :commit_date=> Time.now,
      :message => "Initial import",
      :scm_project=> @scm_project
    }
    @user = User.make(:company=>@scm_project.company, :email => "test@jobsworth.com", :username => "jobsworth_user", :name => "jobsworth user")
  end

  it "should create a new instance given valid attributes" do
    ScmChangeset.create!(@valid_attributes)
  end
  it "should try to map author -> user email" do
    @valid_attributes[:author]= @user.email
    ScmChangeset.create!(@valid_attributes).user.should == @user
  end
  it "should try to map author -> user name" do
    @valid_attributes[:author]= @user.username
    ScmChangeset.create!(@valid_attributes).user.should == @user
  end
  it "should try to map author -> user full name" do
    @valid_attributes[:author]= @user.name
    ScmChangeset.create!(@valid_attributes).user.should == @user
  end
  context "message have task num in #(\d) format and tasks with this num exist in this company" do
    before(:each) do
      @task= Task.make(:company=>@scm_project.company)
      @valid_attributes[:message]= "Commit for task ##{@task.task_num}"
      @changeset= ScmChangeset.create!(@valid_attributes)
    end
    it "should join changeset to  this task" do
      @changeset.task.should_not be_nil
      @changeset.task.should == @task
    end
  end
  describe "hook parsers" do
    describe "github parser" do
     before(:each) do
        @changesets=ScmChangeset.github_parser(GITHUB_PAYLOAD)
        @payload = JSON.parse(GITHUB_PAYLOAD)
      end

      it "should map commits array to array of changesets" do
        @changesets.should have(@payload['commits'].size).changesets
      end

      it "should map id to changeset_rev" do
        @changesets.each_with_index { |changeset, index| changeset[:changeset_rev].should == @payload['commits'][index]['id']}
      end

      it "should map modified array to array of scm_files_attributes with state modified" do
        @changesets.each_with_index do |changeset, index|
          @payload['commits'][index]['modified'].each { |file| changeset[:scm_files_attributes].should include({ :path=>file, :state=>'M'})}
        end
      end

      it "should map added array to array of scm_files_attributes with state added"do
        @changesets.each_with_index do |changeset, index|
          @payload['commits'][index]['added'].each { |file| changeset[:scm_files_attributes].should include({ :path=>file, :state=>'A'})}
        end
      end

      it "should map deleted array to array of scm_files_attributes with status deleted"do
        @changesets.each_with_index do |changeset, index|
          @payload['commits'][index]['deleted'].each { |file| changeset[:scm_files_attributes].should include({ :path=>file, :state=>'D'})}
        end
      end

      it "should map author name to author" do
        @changesets.each_with_index { |changeset, index| changeset[:author].should == @payload['commits'][index]['author']['name'] }
      end

      it "should map timestamp to commit_date" do
        @changesets.each_with_index { |changeset, index| changeset[:commit_date].should == @payload['commits'][index]['timestamp']}
      end

      it "should map message to changeset message" do
        @changesets.each_with_index { |changeset, index| changeset[:message].should == @payload['commits'][index]['message']}
      end
    end
    describe "google praser" do
      before(:each) do
        @changesets=ScmChangeset.google_parser(GOOGLE_PAYLOAD)
        @payload = JSON.parse(GOOGLE_PAYLOAD)
      end

      it "should map revisions array to array of changesets" do
        @changesets.should have(@payload['revisions'].size).changesets
      end

      it "should map revision to changeset_rev" do
        @changesets.each_with_index { |changeset, index| changeset[:changeset_rev].should == @payload['revisions'][index]['revision']}
      end

      it "should map modified array to array of scm_files_attributes with state modified" do
        @changesets.each_with_index do |changeset, index|
          @payload['revisions'][index]['modified'].each { |file| changeset[:scm_files_attributes].should include({ :path=>file, :state=>'M'})}
        end
      end

      it "should map added array to array of scm_files_attributes with state added"do
        @changesets.each_with_index do |changeset, index|
          @payload['revisions'][index]['added'].each { |file| changeset[:scm_files_attributes].should include({ :path=>file, :state=>'A'})}
        end
      end

      it "should map removed array to array of scm_files_attributes with status deleted"do
        @changesets.each_with_index do |changeset, index|
          @payload['revisions'][index]['removed'].each { |file| changeset[:scm_files_attributes].should include({ :path=>file, :state=>'D'})}
        end
      end

      it "should map author to author" do
        @changesets.each_with_index { |changeset, index| changeset[:author].should == @payload['revisions'][index]['author'] }
      end

      it "should map timestamp(from Epoch) to commit_date" do
        @changesets.each_with_index { |changeset, index| changeset[:commit_date].should == Time.at(@payload['revisions'][index]['timestamp'])}
      end

      it "should map message to changeset message" do
        @changesets.each_with_index { |changeset, index| changeset[:message].should == @payload['revisions'][index]['message']}
      end
    end
  end
  describe "create_from_web_hooks" do
    before(:each) do
      @params= { :secret_key => @scm_project.secret_key, :provider=>"github", :payload=> GITHUB_PAYLOAD }
    end
    it "should map secret_key to scm_project" do
      ScmChangeset.create_from_web_hook(@params).each{ |changeset| changeset.scm_project.should == @scm_project }
    end
    it "should return array of created changesets for github" do
      ScmChangeset.create_from_web_hook(@params).should have(2).changesets
    end
    it "should return array of created changesets for google code" do
      @params[:provider]='google'
      @params[:payload] = GOOGLE_PAYLOAD
      ScmChangeset.create_from_web_hook(@params).should have(1).changeset
    end
    it "should return false if any of changesets not saved" do
      @params[:payload] = GITHUB_PAYLOAD.sub("Chris Wanstrath", "")
      ScmChangeset.create_from_web_hook(@params).should == false
    end
    it "should return false if scm_project with this secret_key not exist" do
      @params[:secret_key]="not exist"
      ScmChangeset.create_from_web_hook(@params).should == false
    end
    it "should return false if parser for this provider not exist" do
      @params[:provider]="not exist"
      ScmChangeset.create_from_web_hook(@params).should == false
    end
    it "should rewrite changesets by (scm_project_id, changeset_rev)" do
      ScmChangeset.create_from_web_hook(@params).should have(2).changesets
      changeset=ScmChangeset.last
      message=changeset.message
      changeset.message="changed"
      changeset.save!
      ScmChangeset.create_from_web_hook(@params).should have(2).changesets
      changeset.reload
      changeset.message.should == message
    end
  end
  describe ".for_list method" do
    before(:each) do
      @task=Task.make
      2.times{ ScmChangeset.make(:task=>@task) }
      2.times{ ScmChangeset.make(:scm_project=>@scm_project) }
      2.times{ ScmChangeset.make }
    end
    it "should find all changesets by params[:task_id]" do
      changesets = ScmChangeset.for_list(:task_id=>@task.id)
      changesets.should have(2).changesets
      changesets.each { |changeset| changeset.task.should == @task}
    end
    it "should find all changesets by params[:scm_project_id" do
      changesets = ScmChangeset.for_list(:scm_project_id => @scm_project.id)
      changesets.should have(2).changesets
      changesets.each { |changeset| changeset.scm_project.should == @scm_project }
    end
    it "should return nil if not preseted params[:task_id] nor params[:scm_project_id]" do
      ScmChangeset.for_list(:parameter => 1).should be_nil
    end
  end
end





# == Schema Information
#
# Table name: scm_changesets
#
#  id              :integer(4)      not null, primary key
#  user_id         :integer(4)
#  scm_project_id  :integer(4)
#  author          :string(255)
#  changeset_num   :integer(4)
#  commit_date     :datetime
#  changeset_rev   :string(255)
#  message         :text
#  scm_files_count :integer(4)
#  task_id         :integer(4)
#
# Indexes
#
#  scm_changesets_author_index       (author)
#  scm_changesets_commit_date_index  (commit_date)
#  fk_scm_changesets_user_id         (user_id)
#

