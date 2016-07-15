module ProjectHelpers


  def destroy_project( project )
    project.dependencies.each do |dep|
      dep.remove
    end
    project.remove
  end


  def upload_and_store file, visibility = 'private', name = nil, orga_name = nil, team_name = nil
    project = ProjectImportService.import_from_upload file, @current_user, true, @orga

    project.public = false if visibility.to_s.eql?('private')
    project.public = true  if visibility.to_s.eql?('public')
    project.public = true  if visibility.to_s.empty?
    project.name   = name  if !name.to_s.empty?
    project.save

    if @orga.nil? && @current_user && orga_name.to_s.empty?
      orga = OrganisationService.index(@current_user, true).first
      orga_name = orga.name if orga
    end

    if @orga.nil? && @current_user && !orga_name.to_s.empty?
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
      return false if OrganisationService.allowed_to_transfer_projects?( orga, current_user ) == false

      OrganisationService.transfer project, orga
    end


    def assign_team project, team_name
      return false if project.nil? || project.organisation.nil?

      team = project.organisation.team_by team_name
      return false if team.nil?

      project.teams = [team]
      project.save
    end


end
