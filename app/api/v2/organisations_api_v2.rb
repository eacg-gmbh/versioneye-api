require 'grape'

require_relative 'helpers/session_helpers.rb'

module V2
  class OrganisationsApiV2 < Grape::API
    helpers SessionHelpers

    resource :organisations do

      before do
        authorized?
      end


      desc 'Returns the list of organisations you have access to', {
        notes: %q[
                This endpoint requires the API key from a user. The result is a set of organisations and their API keys.
              ]
      }
      get do
        rate_limit
        track_apikey

        orgas = OrganisationService.index @current_user, true
        present orgas, with: EntitiesV2::OrganisationEntity
      end


      desc 'Returns the inventory list of the organisation', {
        notes: %q[
                Find a detailed description here: https://github.com/versioneye/versioneye-api/blob/master/docs/api/v2/organisation.md
              ]
      }
      params do
        optional :team_name, :type => String, :desc => %Q[Filter by team name]
        optional :language,  :type => String, :desc => %Q[Filter by programming language]
        optional :project_version, :type => String, :desc => %Q[Filter down by project version]
        optional :post_filter, :type => String, :desc => %Q[Post processing filter. Possible values are 'ALL', 'duplicates_only', 'show_duplicates']
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

        pversion  = params[:project_version]
        pversion  = 'ALL' if pversion.to_s.empty?

        post_filter  = params[:post_filter]
        post_filter  = 'ALL' if post_filter.to_s.empty?

        @orga.component_list team, language, pversion, post_filter
      end

    end

  end
end
