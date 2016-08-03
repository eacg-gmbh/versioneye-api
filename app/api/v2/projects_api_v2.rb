
require 'entities_v2'

require_relative 'helpers/project_helpers.rb'
require_relative 'helpers/session_helpers.rb'

module V2

  class ProjectsApiV2 < Grape::API
    helpers ProjectHelpers
    helpers SessionHelpers

    resource :projects do

      before do
        authorized?
      end

      desc "list of projects", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        optional :orga_name, :type => String, :desc => "The name of the organisation the project is assigned to."
        optional :team_name, :type => String, :desc => "The name of the team in the organisation this project is assigned to."
      end
      get '/' do
        rate_limit
        track_apikey

        projects = []
        if @current_user
          filter = {}
          filter[:organisation] = params[:orga_name] if !params[:orga_name].to_s.empty?
          filter[:team]         = params[:team_name] if !params[:team_name].to_s.empty?
          projects = ProjectService.index @current_user, filter
        elsif @orga
          team = nil
          if !params[:team_name].to_s.empty?
            team = @orga.team_by params[:team_name]
          end
          projects = @orga.parent_projects         if team.nil?
          projects = @orga.team_projects(team.ids) if team
        end

        projects.each do |project|
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
        project     = Project.find project_key.to_s
        if project.nil?
          error! "Project `#{params[:project_key]}` dosn't exists", 400
        end

        if current_user && project.is_collaborator?( current_user ) == false
          error! "You are not a collaborator of the requested project", 403
        end

        if @orga && !project.organisation_id.to_s.eql?(@orga.ids)
          error! "You are not a collaborator of the requested project", 403
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
        optional :visibility, :type => String, :desc => "By default 'public'. If 'public' everybody can see the project."
        optional :name, :type => String, :desc => "The name of the VersionEye project. By default it is the filename."
        optional :orga_name, :type => String, :desc => "The name of the organisation this project should be assigned to."
        optional :team_name, :type => String, :desc => "The name of the team in the organisation this project should be assigned to."
        optional :temp, :type => String, :desc => "If 'true' this project will not show up in the UI and gets removed later."
      end
      post do
        rate_limit
        track_apikey

        datafile = ActionDispatch::Http::UploadedFile.new( params[:upload] )
        project_file = {'datafile' => datafile}

        project = nil
        begin
          project = upload_and_store( project_file, params[:visibility], params[:name], params[:orga_name], params[:team_name] )
          project.temp = true if params[:temp].to_s.eql?('true')
          project.save
        rescue => e
          error! e.message, 500
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
        requires :project_key, :type => String, :desc => "Project ID"
        requires :project_file, type: Hash, desc: "Project file - [maven.pom, Gemfile ...]"
      end
      post '/:project_key' do
        rate_limit
        track_apikey

        project_key = params[:project_key]
        project     = Project.find project_key.to_s
        if project.nil?
          error! "Project `#{params[:project_key]}` dosn't exists", 400
        end

        if @current_user && project.is_collaborator?( @current_user ) == false
          error! "You are not a collaborator of the requested project", 403
        end

        if @orga && !project.organisation_id.to_s.eql?(@orga.ids)
          error! "You are not a collaborator of the requested project", 403
        end

        datafile = ActionDispatch::Http::UploadedFile.new( params[:project_file] )
        project_file = {'datafile' => datafile}

        begin
          project = ProjectUpdateService.update_from_upload project, project_file, true
        rescue => e
          error! e.message, 500
        end

        id = project.ids
        Rails.cache.delete( id )
        Rails.cache.delete( "#{id}__flat" )
        Rails.cache.delete( "#{id}__flat-square" )
        Rails.cache.delete( "#{id}__plastic" )
        Badge.where( :key => id.to_s ).delete
        Badge.where( :key => "#{id}__flat" ).delete
        Badge.where( :key => "#{id}__flat-square" ).delete
        Badge.where( :key => "#{id}__plastic" ).delete

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
        requires :project_key, :type => String, :desc => "Delete project with given project ID."
      end
      delete '/:project_key' do
        rate_limit
        track_apikey

        message = ''
        project_key = params[:project_key]
        project     = Project.find project_key.to_s
        if project.nil?
          message = 'Project was removed already.'
        else
          if @current_user && project.is_collaborator?( @current_user ) == false
            error! "You are not a collaborator of the requested project", 403
          end

          if @orga && !project.organisation_id.to_s.eql?(@orga.ids)
            error! "You are not a collaborator of the requested project", 403
          end

          ProjectService.destroy project
          message = "Project deleted successfully."
        end

        {success: true, message: message}
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

        project_key = params[:project_key]
        project     = Project.find project_key.to_s
        if project.nil?
          error! "Project `#{params[:project_key]}` dosn't exists", 400
        end

        if @current_user && project.is_collaborator?( @current_user ) == false
          error! "You are not a collaborator of the requested project", 403
        end

        if @orga && !project.organisation_id.to_s.eql?(@orga.ids)
          error! "You are not a collaborator of the requested project", 403
        end

        licenses = {}

        project.dependencies.each do |dep|
          license = "unknown"
          unless dep[:prod_key].nil?
            product = dep.product
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

        if @current_user.nil? && @orga
          owner_team = @orga.owner_team
          @current_user = owner_team.members.first.user
        end

        ProjectService.merge_by_ga group_id, artifact_id, child_id, @current_user.ids

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

        if @current_user.nil? && @orga
          owner_team = @orga.owner_team
          @current_user = owner_team.members.first.user
        end

        ProjectService.merge parent_id, child_id, @current_user.ids

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

        if @current_user.nil? && @orga
          owner_team = @orga.owner_team
          @current_user = owner_team.members.first.user
        end

        ProjectService.unmerge parent_id, child_id, @current_user.ids

        {success: true}
      end


    end

  end
end
