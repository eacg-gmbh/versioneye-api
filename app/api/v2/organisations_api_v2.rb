require 'grape'

require_relative 'helpers/session_helpers.rb'

module V2
  class OrganisationsApiV2 < Grape::API
    helpers SessionHelpers

    resource :organisations do

      before do
        authorized?
      end

      desc 'Returns the inventory list of the organisation'
      params do
        optional :team_name, :type => String, :desc => %Q[Filter by team name]
        optional :language,  :type => String, :desc => %Q[Filter by programming language]
      end
      get '/:orga_name/inventory' do
        rate_limit
        track_apikey

        if !@orga.name.eql?(params[:orga_name])
          error! "`orga_name` does not match with used API key!", 400
        end

        team      = params[:team_name]
        team      = 'ALL' if team.to_s.empty?
        language  = params[:language]
        language  = 'ALL' if language.to_s.empty?
        inventory = @orga.component_list team, language

        inventory
      end

    end

  end
end
