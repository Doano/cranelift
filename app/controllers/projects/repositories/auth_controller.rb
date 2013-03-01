# encoding: utf-8
class Projects::Repositories::AuthController < ApplicationController
  before_filter :load_vars

  def new
  end

  def create
    project = Project.find(params[:project_id])
    repository = Repository.find(params[:repository_id])

    if repository.auth(params[:login], params[:pass])
      session[:repo_login] = params[:login]
      session[:repo_pass] = params[:pass]
      redirect_to project_repository_url(project, repository)
    else
      render :new, :alert => 'dados errados'
    end
  end

  private
  def load_vars
    @project = Project.find(params[:project_id])
    @repository = Repository.find(params[:repository_id])
  end
end
