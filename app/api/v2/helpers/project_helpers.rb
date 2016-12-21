module ProjectHelpers


  def upload_and_store file, visibility = 'private', name = nil, orga_name = nil, team_name = Team::A_OWNERS, tempp = false
    orga = fetch_orga( orga_name )
    if orga.nil?
      raise "ERROR. Organisation is not defined or you do not have access to it!"
    end

    project = ProjectImportService.import_from_upload file, current_user, true, orga.ids, tempp
    project.public = false if visibility.to_s.eql?('private')
    project.public = true  if visibility.to_s.eql?('public')
    project.public = true  if visibility.to_s.empty?
    project.name   = name  if !name.to_s.empty?
    project.private_project = true
    project.save

    assign_team project, team_name

    project
  end


  private


    def assign_team project, team_name = Team::A_OWNERS
      team_name = Team::A_OWNERS if team_name.to_s.empty?
      return false if project.nil? || project.organisation.nil?

      team = project.organisation.team_by team_name
      return false if team.nil?

      project.teams = [team]
      project.save
    end


    def fetch_orga orga_name
      orga = current_orga
      return orga if orga
      return orga if orga_name.to_s.empty?

      orga = Organisation.where(:name => orga_name).first
      if orga && OrganisationService.member?( orga, current_user )
        @orga = orga
        return orga
      else
        return nil
      end
    end


end
