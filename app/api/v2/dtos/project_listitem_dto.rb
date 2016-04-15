class ProjectListitemDto

  attr_accessor :id, :name, :project_type, :public, :private_scm, :period, :source
  attr_accessor :organisation, :team
  attr_accessor :dep_number,     :out_number,     :licenses_red,     :licenses_unknown
  attr_accessor :dep_number_sum, :out_number_sum, :licenses_red_sum, :licenses_unknown_sum
  attr_accessor :license_whitelist_name
  attr_accessor :created_at, :updated_at

  def update_from project
    self.id              = project.ids
    self.name            = project.name
    self.project_type    = project.project_type
    self.public          = project.public
    self.private_scm     = project.private_project
    self.period          = project.period
    self.source          = project.source

    self.dep_number       = project.dep_number
    self.out_number       = project.out_number
    self.licenses_red     = project.licenses_red
    self.licenses_unknown = project.licenses_unknown

    self.dep_number_sum       = project.dep_number_sum
    self.out_number_sum       = project.out_number_sum
    self.licenses_red_sum     = project.licenses_red_sum
    self.licenses_unknown_sum = project.licenses_unknown_sum

    self.license_whitelist_name = project.license_whitelist_name

    self.organisation = project.organisation.to_s
    if !project.teams.nil? && !project.teams.empty?
      self.team = project.teams.first.to_s
    end

    self.created_at      = project.created_at.strftime("%d.%m.%Y-%H:%M")
    self.updated_at      = project.created_at.strftime("%d.%m.%Y-%H:%M")
  end

end
