require 'grape'
require 'entities_v2'

require_relative 'helpers/session_helpers'
require_relative 'helpers/paging_helpers'
require_relative 'helpers/product_helpers'

module V2
  class GithubApiV2 < Grape::API

    helpers SessionHelpers
    helpers PagingHelpers
    helpers ProductHelpers
    helpers CacheHelpers
    helpers SearchHelpers

    resource :github do

      before do
        track_apikey
        init_cache({expires_in: 300})
      end


      #-- GET '/' -------------------------------------------------------------
      desc "lists your's github repos", {
        notes: %q[
          This endpoint shows all repositories from your Github account.

          This enpoint expects that you have a GitHub account connected and the token
          is still valid. If that is not the case please visit **https://www.versioneye.com/settings/connect**.
          to update your GitHub credentials.

          **PS** If it's shows no or old data, then you can use the `github/sync` endpoint
          to update your account with the current meta data from GitHub.
        ]
      }
      params do
        optional :lang         , type: String, desc: "Filter by language"
        optional :private      , type: Boolean, desc: "Filter by visibility"
        optional :org_name     , type: String, desc: "Filter by name of organization"
        optional :org_type     , type: String, desc: "Filter by type of organization"
        optional :page         , type: String, default: '1', desc: "Number of page"
        optional :only_imported, type: Boolean, default: false, desc: "Show only imported repositories"
      end
      get '/' do
        authorized?
        user = current_user
        github_connected?(user)

        page = params[:page].to_i
        page = 1 if page < 1

        query_filters = {}
        query_filters[:language]    = params[:lang] unless params[:lang].nil?
        query_filters[:private]     = params[:private] unless params[:private].nil?
        query_filters[:owner_login] = params[:org_name] unless params[:org_name].nil?
        query_filters[:owner_type]  = params[:org_type] unless params[:org_type].nil?

        if user.github_repos.all.count == 0
          # try to import users repos when there's no repos.
          GitHubService.cached_user_repos(user)
        end

        if params[:only_imported]
          imported_projects = Project.by_user(user).where(source: Project::A_SOURCE_GITHUB)
          repo_names        = imported_projects.map {|proj| proj[:scm_fullname]}
          repos             = user.github_repos.any_in(fullname: repo_names.to_a).paginate(per_page: 30, page: page)
        else
          repos = user.github_repos.where(query_filters).paginate(per_page: 30, page: page)
        end

        repos.each do |repo|
          imported_projects        = Project.by_user(user).by_github(repo[:fullname]).to_a
          proj_keys                = imported_projects.map {|proj| proj[:project_key]}
          repo[:imported_projects] = proj_keys.to_a
          repo[:repo_key]          = encode_prod_key(repo[:fullname])
        end
        paging = make_paging_object(repos)

        present :repos , repos , with: EntitiesV2::RepoEntity
        present :paging, paging, with: EntitiesV2::PagingEntity
      end


      #-- GET '/github/sync' --------------------------------------------------
      desc "re-load github data", {
        notes: %q[
          Reimports ALL GitHub Repositories. This Endpoint fetches meta information to all
          repositories in your GitHub account. Meta information such as repo name, branches and
          supported project files.

          This endpoint works asynchronously and returns a status code. The status code is either
          **running** or **done**.
        ]
      }
      get '/sync' do
        authorized?
        user = current_user
        github_connected?(user)

        cache = Versioneye::Cache.instance.mc
        user_task_key = "#{user[:username]}-#{user[:github_id]}"
        task_status   = cache.get( user_task_key )

        if task_status != GitHubService::A_TASK_RUNNING && task_status != GitHubService::A_TASK_DONE
          task_status = GitHubService.update_repos_for_user(user)
        end

        present :status, task_status
      end


      #-- GET '/:repo_key' ----------------------------------------------------
      desc "shows the detailed information for the repository", {
        notes: %q[
          Due the limits of our current API framework, the repo key has to be
          encoded as url-safe string. That means all '/' has to be replaced with
          colons ':' and '.' has to be replaced with '~'.

          For example,  repository with fullname `versioneye/veye` has to transformed
          to `versioneye:veye`.
        ]
      }
      params do
        requires :repo_key, type: String, desc: "encoded repo name with optional branch info."
      end
      get '/:repo_key' do
        authorized?
        user = current_user
        github_connected?(user)

        repo_fullname = decode_prod_key(params[:repo_key])
        repo = user.github_repos.by_fullname(repo_fullname).first

        unless repo
          error! "We couldn't finde the repository `#{repo_fullname}` in your account.", 400
        end
        repo_projects = Project.by_user(user).by_github(repo_fullname).to_a

        present :repo, repo, with: EntitiesV2::RepoEntityDetailed
        present :imported_projects, repo_projects, with: EntitiesV2::ProjectEntity
      end


      #-- POST '/:repo_key' --------------------------------------------------
      desc "imports project file from github", {
        notes: %q[
          You can use this API to import your github repo as project.

          Due the limits of our current API framework, the repo key has to be
          encoded as url-safe string. That means all '/' has to be replaced with
          colons ':' and '.' has to be replaced with '~'.

          For example,  repository with fullname `versioneye/veye` has to transformed
          to `versioneye:veye`.
        ]
      }
      params do
        requires :repo_key, type: String, desc: "encoded repo name"
        optional :branch, type: String, default: "master", desc: "the name of the branch"
        optional :file, type: String, default: "Gemfile", desc: "the project file (default is Gemfile)"
      end
      post '/:repo_key' do
        authorized?
        user = current_user
        github_connected?(user)
        repo_name = decode_prod_key(params[:repo_key])
        branch = params[:branch]
        project_file = params[:file]
        project_file = 'Gemfile' if project_file.to_s.empty?

        repo = user.github_repos.by_fullname(repo_name).first
        unless repo
          error! "We couldn't find the repository `#{repo_name}` in your account.", 400
        end

        ProjectImportService.import_from_github(user, repo_name, project_file, branch)
        projects = Project.by_user(current_user).by_github(repo_name).to_a

        present :repo, repo, with: EntitiesV2::RepoEntityDetailed
        present :imported_projects, projects, with: EntitiesV2::ProjectEntity
      end


      #-- DELETE '/:repo_key' -------------------------------------------------
      desc "remove imported project", {
        notes: %q[
          This Endpoint deletes a project on VersionEye!

          Due the limits of our current API framework, the repo key has to be
          encoded as url-safe string. That means all '/' has to be replaced with
          colons ':' and '.' has to be replaced with '~'.

          For example,  repository with fullname `versioneye/veye` has to transformed
          to `versioneye:veye`.
        ]
      }
      params do
        requires :repo_key, type: String, desc: "encoded repo-key"
        optional :branch, type: String, default: "master", desc: "the name of the branch"
        optional :file, type: String, default: "Gemfile", desc: "the project file (default is Gemfile)"
      end
      delete '/:repo_key' do
        authorized?
        user = current_user
        github_connected?(user)

        repo_name = decode_prod_key(params[:repo_key])
        branch    = params[:branch]
        project_file = params[:file]
        project_file = 'Gemfile' if project_file.to_s.empty?

        projects = Project.by_user(user).by_github(repo_name).where(scm_branch: branch)
        error!("Project doesnt exists", 400) if projects.nil? || projects.empty?

        projects.each do |project|
          next if !project.filename.eql?( project_file )
          ProjectService.destroy project[:_id].to_s
        end

        present :success, true
      end


      #-- POST '/hook' -----------------------------------------------
      desc "GitHub Hook", {
        notes: %q[This endpoint is registered as service hook on GitHub. It triggers a project re-parse on each git push. ]
      }
      params do
        requires :project_id, type: String, desc: "Project ID"
      end
      post '/hook/:project_id' do
        Rails.logger.info "hook params: #{params}"
        authorized?
        project = Project.find_by_id( params[:project_id] )

        if project && project.collaborator?( current_user )
          Thread.new{ ProjectService.update( project, project.notify_after_api_update ) }
          present :success, true
        else
          present :success, "No! You do not have access to this project!"
        end
      end



    end #end of resource block
  end
end
