# encoding: utf-8
require 'cranelift'

class Repository < ActiveRecord::Base
  # Callbacks
  before_update do |repo|
    # TODO quando um repositorio ter seu nome alterado, o nome da pasta
    # dos arquivos do repositorio também deve ser alterado
    # 
    # old_repo = Repository.find(repo.id)
    # if old_repository.name =! repo.name entao mude o nome da pasta para repo.name
  end

  before_create do
    scm.checkout
  end

  before_destroy do
    scm.delete_files
  end


  # Relatioships
  belongs_to :project


  # Validations
  validates_presence_of :project

  validates :name,
    :presence => true,
    :uniqueness => { :scope => :project_id },
    :format => { :with => /\A\w+\z/, :message => 'É permitido apenas letras e números no nome' },
    :length => {:in => 3..32}

  validates :url,
    :presence => :true,
    :format => { :with => /^http[s]{,1}:\/\/[\w\.\-\%\#\=\?\&]+\.([\w\.\-\%\#\=\?\&]+\/{,1})*/i }

  validates :autoupdate_login,
    :presence => true,
    :if => "enable_autoupdate == true"

  validates :autoupdate_password,
    :presence => true,
    :if => "enable_autoupdate == true"

  validate :check_valid_repository, :on => :create

  # TODO usar/mover uma classe abstrata para decidir qual scm usar
  class Scm
    def initialize(proj)
      @project = proj
    end

    def checkout
      if File.directory?(@project.project_path)
        # TODO dar um raise em um erro aki?
        puts 'Erro, diretório já existe'
      else
        svn.checkout(@project.url, @project.project_path)
      end
    end

    def update (rev)
      svn.update(@project.project_path, rev)
    end

    def log (start = 0, limit = 0)
      svn.log(@project.project_path, start, 'HEAD', limit)
    end

    def delete_files
      if File.directory?(@project.project_path)
        FileUtils.rm_rf(@project.project_path)
      end
    end

    def info
      svn.info(@project.url)
    end

    def svn
      @svn ||= ::Cranelift::SvnScm.new
    end
  end

  def scm
    @scm ||= Scm.new(self)
  end

  def project_path
    # Assumimos que o nome é sempre validado (sanitizado)
    File.join(Rails.root, 'repositories', self.project.name, self.name)
  end


  private

  def check_valid_repository
    errors.add(:url, 'URL especificada não é um repositório svn válido') if scm.info.nil?
  end
end
