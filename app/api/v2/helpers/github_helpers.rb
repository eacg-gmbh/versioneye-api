module GithubHelpers


  def handle_pull_request params
    json_params = params.to_json.deep_symbolize_keys!
    action = json_params[:action]
    number = json_params[:number]

    pull_request = json_params[:pull_request]
    commits_url  = pull_request[:commits_url]

    Rails.logger.info "Pull Request #{number} #{action} - #{commits_url}"

    response = HttpService.fetch_response commits_url
    commits = JSON.parse response.body
    Rails.logger.info "commits: #{commits}"
    # last_commit = commits.last
    # sha = last_commit['commit']['tree']['sha']
    # url = last_commit['commit']['tree']['url']

    Rails.logger.info "Going to check #{sha} - #{url}"
    # TODO do the actual checking thing!

    "Done"
  end


  def handle_commit params
    project_file_changed = false
    commits = params[:commits] # Returns an Array of Hash
    commits = [] if commits.nil?
    commits.each do |commit|
      commit.deep_symbolize_keys!
      Rails.logger.info "GitHub hook for commit #{commit[:url]} with commit message -#{commit[:message]}-"
      modified_files = commit[:modified] # Array of modifield files
      modified_files.each do |file_path|
        next if ProjectService.type_by_filename( file_path ).nil?

        project_file_changed = true
        break
      end
    end

    if project_file_changed == false
      error! "Dependencies did not change.", 400
    end

    project = Project.find_by_id( params[:project_id] )
    if project.nil?
      error! "Project with ID #{params[:project_id]} not found.", 400
    end

    if !project.is_collaborator?( current_user )
      error! "You do not have access to this project!", 400
    end

    message = ''
    branch = params[:ref].to_s.gsub('refs/heads/', '')
    if project.scm_branch.to_s.eql?( branch )
      ProjectUpdateService.update_async project, project.notify_after_api_update
      message = "A background job was triggered to update the project #{project.scm_fullname} (#{project.ids})."
    else
      message = "Project branch is #{project.scm_branch} but branch in payload is #{branch}. As the branches are not matching we will ignore this."
    end
    message
  end


end
