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
        detail: %q[
This endpoint requires the API key from a user. The result is a set of organisations and their API keys.
              ]
      }
      get do
        rate_limit
        track_apikey

        orgas = OrganisationService.index @current_user, true
        present orgas, with: EntitiesV2::OrganisationEntity
      end


      desc 'Returns the list of teams'
      get '/:orga_name/teams' do
        rate_limit
        track_apikey

        if @orga.nil?
          error! "Please use a valid API key from the target organisation.", 400
        end
        if !@orga.name.eql?(params[:orga_name])
          error! "`orga_name` does not match with used API key!", 400
        end

        present @orga.teams, with: EntitiesV2::TeamEntity
      end


      desc 'Returns the list of projects'
      get '/:orga_name/projects' do
        rate_limit
        track_apikey

        if @orga.nil?
          error! "Please use a valid API key from the target organisation.", 400
        end
        if !@orga.name.eql?(params[:orga_name])
          error! "`orga_name` does not match with used API key!", 400
        end

        present @orga.projects, with: EntitiesV2::ProjectListItemEntity
      end


      desc 'Returns the inventory list of the organisation', {
        detail: %q[
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

        if @orga.nil?
          error! "Please use a valid API key from the target organisation.", 400
        end
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


      desc 'Creates an inventory diff object', {
        detail: %q[
This Endpoint takes 2 inventory filters and calculates the difference between them.
The diff object contains wich items have been removed and/or added compared to the inventory1 filter.
The response of this Endpoint is the ID of the diff object, which is calculated async in the background.
              ]
      }
      params do
        optional :f1_team_name, :type => String, :desc => %Q[Inventory1, filter by team name]
        optional :f1_language,  :type => String, :desc => %Q[Inventory1, filter by programming language]
        optional :f1_project_version, :type => String, :desc => %Q[Inventory1, filter down by project version]
        optional :f1_post_filter, :type => String, :desc => %Q[Inventory1, post processing filter. Possible values are 'ALL', 'duplicates_only', 'show_duplicates']
        optional :f2_team_name, :type => String, :desc => %Q[Inventory2, filter by team name]
        optional :f2_language,  :type => String, :desc => %Q[Inventory2, filter by programming language]
        optional :f2_project_version, :type => String, :desc => %Q[Inventory2, filter down by project version]
        optional :f2_post_filter, :type => String, :desc => %Q[Inventory2, post processing filter. Possible values are 'ALL', 'duplicates_only', 'show_duplicates']
      end
      post '/:orga_name/inventory_diff' do
        rate_limit
        track_apikey

        if @orga.nil?
          error! "Please use a valid API key from the target organisation.", 400
        end
        if !@orga.name.eql?(params[:orga_name])
          error! "`orga_name` does not match with used API key!", 400
        end

        team      = params[:f1_team_name]
        team      = 'ALL' if team.to_s.empty?

        language  = params[:f1_language]
        language  = 'ALL' if language.to_s.empty?

        pversion  = params[:f1_project_version]
        pversion  = 'ALL' if pversion.to_s.empty?

        post_filter  = params[:f1_post_filter]
        post_filter  = 'ALL' if post_filter.to_s.empty?

        filter1 = {:team => team, :language => language, :version => pversion, :after_filter => post_filter}

        team      = params[:f2_team_name]
        team      = 'ALL' if team.to_s.empty?

        language  = params[:f2_language]
        language  = 'ALL' if language.to_s.empty?

        pversion  = params[:f2_project_version]
        pversion  = 'ALL' if pversion.to_s.empty?

        post_filter  = params[:f2_post_filter]
        post_filter  = 'ALL' if post_filter.to_s.empty?

        filter2 = {:team => team, :language => language, :version => pversion, :after_filter => post_filter}

        diff_id = OrganisationService.inventory_diff_async @orga.name, filter1, filter2

        {success: true, diff_id: "#{diff_id}"}
      end


      desc 'Returns the inventory diff object', {
        detail: %q[

              ]
      }
      params do
        optional :inventory_diff_id, :type => String, :desc => %Q[ID of the inventory diff object]
      end
      get '/:orga_name/inventory_diff' do
        rate_limit
        track_apikey

        if @orga.nil?
          error! "Please use a valid API key from the target organisation.", 400
        end
        if !@orga.name.eql?(params[:orga_name])
          error! "`orga_name` does not match with used API key!", 400
        end

        idiff = InventoryDiff.find params[:inventory_diff_id].to_s
        if idiff.nil?
          error! "given `diff id` does not exist!", 400
        end

        present idiff, with: EntitiesV2::InventoryDiffEntity
      end
    end

  end
end
