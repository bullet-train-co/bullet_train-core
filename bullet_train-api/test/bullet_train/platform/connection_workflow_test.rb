require "test_helper"

class BulletTrain::Platform::ConnectionWorkflowTest < ActiveSupport::TestCase
#class BulletTrain::Platform::ConnectionWorkflowTest < ActionController::TestCase
  #class TestController < ActionController::Base
    #def params
      #{}
    #end
    #def workflow_caller
      #binding.irb
      #@workflow = BulletTrain::Platform::ConnectionWorkflow.new
      #@workflow.to_proc.call()
    #end
    #private
    #def current_user
      #User.new
    #end
  #end

  #tests TestController

  #def with_routing
    ## http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-with_routing
    ## http://guides.rubyonrails.org/routing.html#connecting-urls-to-code
    #super do |set|
      #set.draw do
        #get 'workflow_caller', to: 'bullet_train/platform/connection_workflow_test/test#workflow_caller'
      #end

      #yield
    #end
  #end

  setup do
    @workflow = BulletTrain::Platform::ConnectionWorkflow.new
  end

  test "to_proc returns a proc" do
    assert_equal "Proc", @workflow.to_proc.class.name
  end

  def params
    {}
  end

  def current_user
    nil
  end

  def request
    OpenStruct.new url: "http://some-return.url"
  end

  def new_user_session_path(params)
    nil
  end

  def redirect_to(path)
    nil
  end

  test "calling the proc creates a User and a Membership" do
    params = {}
    instance_eval(&@workflow)
    assert_equal 1, User.count
    assert_equal 1, Membership.count
  end

  #test "calling the workflow creates a user and a membership" do
    #with_routing do
      #get :workflow_caller, format: :json, params: {}
      ##the_proc = @workflow.to_proc
      ###the_proc.params = {}
      ##the_proc.call()
      #assert_equal 1, User.count
      #assert_equal 1, Membership.count
    #end
  #end
end
