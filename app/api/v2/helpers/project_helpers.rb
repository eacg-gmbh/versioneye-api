module ProjectHelpers


  def fetch_project_by_key_and_user(project_key, current_user)
    project = Project.find project_key.to_s
    if project && project.is_collaborator?( current_user )
      return project
    end
    nil
  end


  def destroy_project(project_id)
    project = Project.find_by_id(project_id)
    project.dependencies.each do |dep|
      dep.remove
    end
    project.remove
  end


  def upload_and_store file, visibility = 'private', name = nil, orga_name = nil, team_name = nil
    project = ProjectImportService.import_from_upload file, current_user, true

    project.public = true  if visibility.to_s.eql?('public')
    project.public = false if visibility.to_s.eql?('private')
    project.name   = name  if !name.to_s.empty?
    project.save

    if !orga_name.to_s.empty?
      assign_organisation project, orga_name
    end
    if !team_name.to_s.empty?
      assign_team project, team_name
    end

    project
  end


  private


    def assign_organisation project, orga_name
      orga = Organisation.where(:name => orga_name).first
      return false if orga.nil?
      return false if !OrganisationService.allowed_to_transfer_projects?( orga, current_user )

      project.organisation_id = orga.ids
      project.teams = [orga.owner_team]
      project.save
    end


    def assign_team project, team_name
      team = project.organisation.team_by team_name
      return false if team.nil?

      project.teams = [team]
      project.save
    end


end
