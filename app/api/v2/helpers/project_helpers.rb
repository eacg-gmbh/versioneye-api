module ProjectHelpers


  def upload_and_store file, visibility = 'private', name = nil, orga_name = nil, team_name = Team::A_OWNERS, tempp = false
    orga = current_orga
    orga_id = nil
    orga_id = orga.ids if orga
    project = ProjectImportService.import_from_upload file, current_user, true, orga_id, tempp

    project.public = false if visibility.to_s.eql?('private')
    project.public = true  if visibility.to_s.eql?('public')
    project.public = true  if visibility.to_s.empty?
    project.name   = name  if !name.to_s.empty?
    project.private_project = true
    project.save

    if orga_name.to_s.empty? && @current_user
      orga = OrganisationService.index(@current_user, true).first
      orga_name = orga.name if orga
    end

    if !orga_name.to_s.empty? && @current_user
      assign_organisation project, orga_name
    end

    assign_team project, team_name

    project
  end


  private


    def assign_organisation project, orga_name
      orga = Organisation.where(:name => orga_name).first
      return false if orga.nil?
      return false if OrganisationService.allowed_to_transfer_projects?( orga, current_user ) == false

      OrganisationService.transfer project, orga
    end


    def assign_team project, team_name = Team::A_OWNERS
      team_name = Team::A_OWNERS if team_name.to_s.empty?
      return false if project.nil? || project.organisation.nil?

      team = project.organisation.team_by team_name
      return false if team.nil?

      project.teams = [team]
      project.save
    end


end
