require 'grape'

require_relative 'helpers/session_helpers.rb'

module V2
  class SecurityApiV2 < Grape::API
    helpers SessionHelpers
    helpers ProductHelpers
    helpers PagingHelpers

    resource :security do

      before do
        rate_limit
        track_apikey
      end

      desc 'Security Vulnerabilities'
      params do
        requires :language, :type => String, :desc => %q[Filter by programming languages]
        optional :prod_key, :type => String, :desc => %q[prod_key of the package]
        optional :page,     :type => Integer, :desc => "Specify page for paging", :regexp => /^[\d]+$/
        optional :asc_sort, :type => String, :desc => "Asc sort by value"
        optional :desc_sort, :type => String, :desc => "Desc sort by value"
      end
      get '/' do
        orga = current_orga
        if env.to_s.eql?('production') && (orga.nil? || orga.plan.nil? || orga.plan.price.to_i == 0)
          error! "This API endpoint is only for paying customers. Please upgrade your plan.", 403
        end

        prod_key = decode_prod_key(params[:prod_key])
        lang = get_language_param(params[:language])
        page = 0
        page = (params[:page].to_i - 1) if !params[:page].to_s.empty?
        per_page = 30
        skip = per_page * page
        data = SecurityVulnerability.where(:language => lang)
        if !prod_key.to_s.empty?
          data = data.where(:prod_key => prod_key )
        end
        if !params[:asc_sort].to_s.empty?
          data = data.asc( params[:asc_sort] )
        elsif !params[:desc_sort].to_s.empty?
          data = data.desc( params[:desc_sort] )
        end
        data = data.skip(skip).limit(per_page)
        total_count = data.count
        paging      = make_paging_for_references( page + 1, total_count )
        results     = SearchResults.new paging: paging, entries: data
        present results, with: EntitiesV2::SecurityResultEntity
      end

    end

  end
end
