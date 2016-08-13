class Me

  attr_accessor :username, :fullname, :email, :admin, :organisation, :deleted_user
  attr_accessor :enterprise_projects, :rate_limit, :comp_limit, :active
  attr_accessor :notifications

  def update_from_user user
    self.username     = user.username
    self.fullname     = user.fullname
    self.email        = user.email
    self.admin        = user.admin
    self.deleted_user = user.deleted_user
  end

  def update_from_orga orga
    self.organisation = orga.name
  end

end
