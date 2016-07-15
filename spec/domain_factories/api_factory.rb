class ApiFactory

  def self.create_new(user = nil, save = true)
    user = UserFactory.create_new(101) if user.nil?
    if user.nil?
      Rails.logger.error "User is not specified or can't create random test-user"
      Rails.logger.error user.errors.full_messages.to_sentence
      return nil
    end
    new_api_key = Api.generate_api_key
    @user_api = Api.new user_id: user.id, api_key: new_api_key

    if save
      unless @user_api.save
        p @user_api.errors.full_messages.to_sentence
      end
    end
    @user_api
  end


  def self.create_new_for_orga(orga, save = true)
    if orga.nil?
      Rails.logger.error "Orga is not specified or can't create random test-orga"
      return nil
    end
    new_api_key = Api.generate_api_key
    @orga_api   = Api.new organisation_id: orga.ids, api_key: new_api_key

    if save
      unless @orga_api.save
        p @orga_api.errors.full_messages.to_sentence
      end
    end
    @orga_api
  end


end
