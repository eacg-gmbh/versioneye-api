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


  def upload_and_store file, visibility = 'private', name = nil, orga_name = nil
    project = ProjectImportService.import_from_upload file, current_user, true

    project.public = true  if visibility.to_s.eql?('public')
    project.public = false if visibility.to_s.eql?('private')
    project.name   = name  if !name.to_s.empty?

    if !orga_name.to_s.empty?
      OrganisationService.index(current_user).each do |orga|
        if orga.name.eql?(orga_name) && OrganisationService.owner?( orga, current_user )
          project.organisation_id = orga.ids
          project.teams.push( orga.owner_team )
        end
      end
    end

    project.save
    project
  end


end
