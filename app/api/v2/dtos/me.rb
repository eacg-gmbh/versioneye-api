class Me

  attr_accessor :username, :fullname, :email, :admin, :deleted_user, :enterprise_projects, :active
  attr_accessor :notifications

  def initialize user 
    self.username     = user.username
    self.fullname     = user.fullname
    self.email        = user.email
    self.admin        = user.admin
    self.deleted_user = user.deleted_user
  end

end
