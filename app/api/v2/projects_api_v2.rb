require 'grape'
require 'entities_v2'

require_relative 'helpers/project_helpers.rb'
require_relative 'helpers/session_helpers.rb'

module V2

  class ProjectsApiV2 < Grape::API
    helpers ProjectHelpers
    helpers SessionHelpers

    def self.fetch_project(user, proj_key)
      project = Project.by_user(user).where(project_key: proj_key).shift
      project = Project.by_user(user).where(_id: proj_key).shift if project.nil?
      project
    rescue => e
      p e.message
      nil
    end

    def self.fetch_product(dep)
      if !dep.group_id.to_s.empty? && !dep.artifact_id.to_s.empty?
        return Product.find_by_group_and_artifact dep.group_id, dep.artifact_id
      else
        return Product.fetch_product( dep.language, dep.prod_key )
      end
    end

    resource :projects do

      before do
        authorized?
      end

      desc "shows user`s projects", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      get do
        rate_limit
        track_apikey

        projects = []
        user_projects = ProjectService.index @current_user
        user_projects.each do |project|
          project_dto = ProjectListitemDto.new
          project_dto.update_from project
          projects << project_dto
        end
        present projects, with: EntitiesV2::ProjectListItemEntity
      end


      desc "shows the project's information", {
        notes: %q[ It shows detailed info of your project. ]
      }
      params do
        requires :project_key, :type => String, :desc => "Project ID"
      end
      get '/:project_key' do
        rate_limit
        track_apikey

        project_key = params[:project_key]
        project     = fetch_project_by_key_and_user(project_key, current_user)
        if project.nil?
          error! "Project `#{params[:project_key]}` don't exists", 400
        end
        present project, with: EntitiesV2::ProjectEntity, type: :full
      end


      desc "upload project file and create a new project", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :upload, type: Hash, desc: "Project file - [maven.pom, Gemfile ...]"
        optional :visibility, :type => String, :desc => "By default 'private'. If 'public' everybody can see the project."
        optional :name, :type => String, :desc => "The name of the VersionEye project. By default it is the filename."
      end
      post do
        if params[:upload].nil?
          error! "Didnt submit file or used wrong parameter.", 400
        end

        if params[:upload].is_a? String
          error! "File field is plain text! It should be a multipart submition.", 400
        end

        datafile = ActionDispatch::Http::UploadedFile.new( params[:upload] )
        project_file = {'datafile' => datafile}

        project = upload_and_store( project_file, params[:visibility], params[:name] )
        if project.nil?
          error! "Can't save uploaded file. Probably our fileserver got cold.", 500
        elsif project.is_a? String
          error! project, 500
        end

        present project, with: EntitiesV2::ProjectEntity, :type => :full
      end


      desc "update project with new file", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :project_key, :type => String, :desc => "Project specific identificator"
        requires :project_file, type: Hash, desc: "Project file - [maven.pom, Gemfile ...]"
      end
      post '/:project_key' do
        project = fetch_project_by_key_and_user( params[:project_key], current_user )
        if project.nil?
          error! "Project `#{params[:project_key]}` don't exists", 400
        end

        if params[:project_file].nil?
          error! "No file submitted or used wrong parameter name.", 400
        end

        if params[:project_file].is_a? String
          error! "File field is plain text. It should be multipart submition.", 400
        end

        datafile = ActionDispatch::Http::UploadedFile.new( params[:project_file] )
        project_file = {'datafile' => datafile}

        project = ProjectUpdateService.update_from_upload project, project_file, current_user, true
        if project.nil?
          error! "Can't save uploaded file. Probably our fileserver got cold.", 500
        elsif project.is_a? String
          error! project, 500
        end

        Rails.cache.delete( project.ids )
        badge = BadgeService.badge_for project.ids
        badge.delete if badge
        project = Project.find project.ids # Reload from DB!

        present project, with: EntitiesV2::ProjectEntity, :type => :full
      end


      desc "delete given project", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :project_key, :type => String, :desc => "Delete project file"
      end
      delete '/:project_key' do
        rate_limit
        track_apikey

        proj_key = params[:project_key]
        error!("Project key can't be empty", 400) if proj_key.nil? or proj_key.empty?

        project = Project.by_user(@current_user).where(_id: proj_key).shift
        project = Project.by_user(@current_user).where(project_key: proj_key).shift if project.nil?
        if project.nil?
          error! "Deletion failed because you don't have such project: #{proj_key}", 500
        else
          destroy_project(project.id)
        end

        {success: true, message: "Project deleted successfully."}
      end


      desc "get grouped view of licences for dependencies", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :project_key, :type => String, :desc => "Project ID or project_key"
      end
      get '/:project_key/licenses' do
        rate_limit
        track_apikey

        project = ProjectsApiV2.fetch_project @current_user, params[:project_key]
        error!("Project `#{params[:project_key]}` don't exists", 400) if project.nil?

        licenses = {}

        project.dependencies.each do |dep|
          license = "unknown"
          unless dep[:prod_key].nil?
            product = ProjectsApiV2.fetch_product dep
            license = product.license_info if product
          end

          licenses[license] ||= []

          prod_info = {
            :name => dep.name,
            :prod_key => dep[:prod_key],
          }
          licenses[license] << prod_info
        end

        {success: true, licenses: licenses}
      end


      desc "merge a project into another one", {
        notes: %q[

              This endpoint merges a project (child_id) into another project (group_id/artifact_id).
              This endpoint is specially for Maven based projects!
              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :group_id,    :type => String, :desc => "GroupId of the parent project"
        requires :artifact_id, :type => String, :desc => "ArtifactId of the parent project"
        requires :child_id,    :type => String, :desc => "Project ID of the child"
      end
      get '/:group_id/:artifact_id/merge_ga/:child_id' do
        rate_limit
        track_apikey

        group_id    = params[:group_id].to_s.gsub('~', '.').gsub(':', '/')
        artifact_id = params[:artifact_id].to_s.gsub('~', '.').gsub(':', '/')
        child_id    = params[:child_id]

        parent = Project.find_by_ga group_id, artifact_id
        if parent.nil?
          error! "Project `#{group_id}/#{artifact_id}` doesn't exists", 400
        end

        child = Project.find child_id
        if child.nil?
          error! "Project `#{child_id}` doesn't exists", 400
        end

        ProjectService.merge_by_ga group_id, artifact_id, child_id, current_user.id

        {success: true}
      end


      desc "merge a project into another one", {
        notes: %q[

              This endpoint merges a project (child_id) into another project (parent_id).
              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :parent_id, :type => String, :desc => "Project ID of the parent"
        requires :child_id, :type => String, :desc => "Project ID of the child"
      end
      get '/:parent_id/merge/:child_id' do
        rate_limit
        track_apikey

        parent_id = params[:parent_id]
        child_id  = params[:child_id]

        parent = Project.find parent_id
        if parent.nil?
          error! "Project `#{parent_id}` doesn't exists", 400
        end

        child = Project.find child_id
        if child.nil?
          error! "Project `#{child_id}` doesn't exists", 400
        end

        ProjectService.merge parent_id, child_id, current_user.id

        {success: true}
      end


      desc "unmerge a project", {
        notes: %q[

              This endpoint unmerges a project (child_id) from another project (parent_id). It makes the
              chilld again a separate project!
              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :parent_id, :type => String, :desc => "Project ID of the parent"
        requires :child_id, :type => String, :desc => "Project ID of the child"
      end
      get '/:parent_id/unmerge/:child_id' do
        rate_limit
        track_apikey

        parent_id = params[:parent_id]
        child_id  = params[:child_id]

        parent = Project.find parent_id
        if parent.nil?
          error! "Project `#{parent_id}` doesn't exists", 400
        end

        child = Project.find child_id
        if child.nil?
          error! "Project `#{child_id}` doesn't exists", 400
        end

        ProjectService.unmerge parent_id, child_id, current_user.id

        {success: true}
      end


    end

  end
end
