require 'grape'
require 'entities_v2'

require_relative 'helpers/session_helpers'
require_relative 'helpers/product_helpers'
require_relative 'helpers/paging_helpers'


module V2
  class  ProductsApiV2 < Grape::API

    helpers ProductHelpers
    helpers SessionHelpers
    helpers PagingHelpers

    resource :products do

      desc "search packages", {
        detail: %q[
This resource returns same results as our web application. But you get it as JSON objects -
the result is an JSON array of product objects.

When there's no match for the query, the result array will be empty.
              ]
      }
      params do
        requires :q, :type => String, :desc => "Query string. At least 2 characters."
        optional :lang, :type => String,
                        :desc => %q[Filter results by programming languages;
                                  For filtering multiple languages submit a comma separated list of language strings.
                                ]
        optional :g, :type => String, :desc => "Filter by GroupID. This is Java/Maven specific"
        optional :page, :type => Integer, :desc => "Specify page for paging", :regexp => /^[\d]+$/
      end
      get '/search/:q' do
        rate_limit
        track_apikey

        query    = parse_query(params[:q])
        group_id = params[:g]
        lang     = get_language_param(params[:lang])
        page_nr  = params[:page]
        page_nr  = nil if page_nr.to_i < 1 #will_paginate can't handle 0
        if query.length < 2
          error! "Search term was too short.", 400
        end

        languages = get_language_array(lang)

        start_time     = Time.now
        search_results = ProductService.search(query, group_id, languages, page_nr)

        query_data = SearchResults.new({query: query, group_id: group_id, languages: languages})
        paging     = make_paging_object(search_results)
        data       = SearchResults.new({query: query_data, paging: paging, entries: search_results.entries})

        present data, with: EntitiesV2::ProductSearchEntity
      end


      desc "search by SHA value", {
        detail: %q[
This Endpoint expects a SHA value and returns the corresponding product to it, if available.
              ]
      }
      get '/sha/:sha' do
        rate_limit
        track_apikey
        authorized?

        artefacts = Artefact.where(:sha_value => params[:sha].to_s)
        present artefacts, with: EntitiesV2::ArtefactEntity
      end


      desc "detailed information for specific package", {
        detail: %q[
Please replace all slashes `/` through colons `:` and all dots `.` through `~`!

Example: The clojure package `yummy.json/json` has to be transformed to  `yummy~json:json`.

#### Notes about status codes

  * API returns 404, when the product with given product key doesnt exists.

  * Response 302 means that you didnt encode prod_key correctly.* (Replace all dots & slashes ) *
              ]
      }
      params do
        requires :lang, :type => String, :desc => %Q["Name of programming language"]
        requires :prod_key, :type => String,
                            :regexp => /[\w|:|~|-|\.]+/,
                            :desc => %Q["Encoded product key, replace all `/` and `.`]
        optional :prod_version, :type => String, :desc => %Q["Version string"]
      end
      get '/:lang/:prod_key' do
        cmp_limit # Check component limit
        track_apikey

        product = fetch_product(params[:lang], params[:prod_key])
        prod_version = params[:prod_version]
        if !prod_version.to_s.empty?
          version_obj = product.version_by_number prod_version
          product.version = prod_version if version_obj
        end

        present product, with: EntitiesV2::ProductEntityDetailed, type: :full
      end


      desc "list versions of a package", {
        detail: %q[
Please replace all slashes `/` through colons `:` and all dots `.` through `~`!

Example: The clojure package `yummy.json/json` has to be transformed to  `yummy~json:json`.

#### Notes about status codes

  * API returns 404, when the product with given product key doesnt exists.

  * Response 302 means that you didnt encode prod_key correctly.* (Replace all dots & slashes ) *
              ]
      }
      params do
        requires :lang, :type => String, :desc => %Q["Name of programming language"]
        requires :prod_key, :type => String,
                            :regexp => /[\w|:|~|-|\.]+/,
                            :desc => %Q["Encoded product key, replace all `/` and `.`]
      end
      get '/:lang/:prod_key/versions' do
        cmp_limit # Check component limit
        track_apikey

        product = fetch_product(params[:lang], params[:prod_key])

        present product, with: EntitiesV2::ProductEntityVersions, type: :full
      end


      desc "check your following status", {
        detail: %q[
Please replace all slashes `/` through colons `:` and all dots `.` through `~`!

Example: The clojure package `yummy.json/json` has to be transformed to  `yummy~json:json`.

#### Notes about status codes

This resource will returns the status code 404 if there is no product
for the given prod_key.
              ]
      }
      params do
        requires :lang, :type => String, :desc => %Q["Name of programming language"]
        requires :prod_key, :type => String, :desc => "Package specifier"
      end
      get '/:lang/:prod_key/follow' do
        rate_limit
        track_apikey
        authorized?
        if @current_user.nil?
          error! "For this action a user is required.", 403
        end
        current_product = fetch_product(params[:lang], params[:prod_key])
        user_follow = UserFollow.new
        user_follow.username = @current_user.username
        user_follow.prod_key = current_product.prod_key
        user_follow.follows  = @current_user.products.to_a.include? current_product

        present user_follow, with: EntitiesV2::UserFollowEntity
      end


      desc "follow your favorite software package", {
        detail: %q[
Please replace all slashes `/` through colons `:` and all dots `.` through `~`!

Example: The clojure package `yummy.json/json` has to be transformed to  `yummy~json:json`.

#### Notes about status codes

It will respond 404, when you are using wrong product key or encode it uncorrectly.
              ]
        }
      params do
        requires :lang, :type => String, :desc => %Q[Programming language]
        requires :prod_key, :type => String,
                            :desc => %Q{ Package product key. }
      end
      post '/:lang/:prod_key/follow' do
        rate_limit
        track_apikey
        authorized?
        if @current_user.nil?
          error! "For this action a user is required.", 403
        end

        current_product = fetch_product(params[:lang], params[:prod_key])
        result = ProductService.follow current_product.language, current_product.prod_key, current_user
        if result == false
          error!("Something went wrong", 400)
        end

        user_follow = UserFollow.new
        user_follow.username = @current_user.username
        user_follow.prod_key = current_product.prod_key
        user_follow.follows  = result

        present user_follow, with: EntitiesV2::UserFollowEntity
      end


      desc "unfollow given software package", {
        detail: %Q[
Please replace all slashes `/` through colons `:` and all dots `.` through `~`!

Example: The clojure package `yummy.json/json` has to be transformed to  `yummy~json:json`.

#### Response codes

  * 400 - bad request; you used wrong product key;
  * 401 - unauthorized - please append api_key
  * 403 - forbidden; you are not authorized; or just missed api_key;
        ]
      }
      params do
        requires :lang, :type => String, :desc => %Q{Programming language}
        requires :prod_key, :type => String, :desc => "Package specifier"
      end
      delete '/:lang/:prod_key/follow' do
        rate_limit
        track_apikey
        authorized?
        if @current_user.nil?
          error! "For this action a user is required.", 403
        end

        current_product = fetch_product(params[:lang], params[:prod_key])
        result = ProductService.unfollow current_product.language, current_product.prod_key, current_user
        if result == false
          error!("Something went wrong", 400)
        end

        user_follow = UserFollow.new
        user_follow.username = @current_user.username
        user_follow.prod_key = current_product.prod_key
        user_follow.follows  = !result

        present user_follow, with: EntitiesV2::UserFollowEntity
      end


      desc "references", {
        detail: %q[
It returns the references of a package.

Please replace all slashes `/` through colons `:` and all dots `.` through `~`!

Example: The clojure package `yummy.json/json` has to be transformed to  `yummy~json:json`.

#### Notes about status codes

This resource will return the status code 404 if there is no product for
the given prod_key or the product has 0 references.
              ]
      }
      params do
        requires :lang, :type => String, :desc => "Language"
        requires :prod_key, :type => String, :desc => "Product Key"
        optional :page, :type => Integer, :desc => "Page for paging", :regexp => /^[\d]+$/
      end
      get '/:lang/:prod_key/references' do
        rate_limit
        track_apikey

        page     = params[:page]
        page     = 1 if page.to_i < 1
        product = fetch_product(params[:lang], params[:prod_key])

        reference = ReferenceService.find_by product.language, product.prod_key
        if reference.nil?
          error! "Zero references for `#{params[:lang]}`/`#{params[:prod_key]}`", 404
        end

        products   = reference.products page
        if products.nil? || products.empty?
          error! "Zero references for `#{params[:lang]}`/`#{params[:prod_key]}`", 404
        end

        total_count = reference.ref_count

        query_data = SearchResults.new lang: product.language, prod_key: product.prod_key
        paging     = make_paging_for_references( page, total_count )
        results    = SearchResults.new query: query_data, paging: paging, entries: products

        present results, with: EntitiesV2::ProductReferenceEntity
      end


      desc "upload scm changelogs to an artifact", {
        detail: %q[
This resource can parse a changelog.xml from the maven-changelog-plugin, assign
it to a specific artifact and display the changelog infos on the product page.

Please replace all slashes `/` through colons `:` and all dots `.` through `~`!

Example: The clojure package `yummy.json/json` has to be transformed to  `yummy~json:json`.

#### Notes about status codes

It will respond 404, when you are using wrong product key or encode it uncorrectly.
              ]
        }
      params do
        requires :lang, :type => String, :desc => %Q[ programming language ]
        requires :prod_key, :type => String, :desc => %Q{ product key }
        requires :prod_version, :type => String, :desc => %Q[ product version ]
        requires :scm_changes_file, type: Hash, desc: "changelog.xml"
      end
      post '/:lang/:prod_key/:prod_version/scm_changes' do
        rate_limit
        track_apikey
        authorized?

        product = fetch_product(params[:lang], params[:prod_key])

        # User needs to be admin or maintainer of the artifact!
        key = "#{product.language}::#{product.prod_key}".downcase
        if current_user.admin == false && !current_user.maintainer.to_a.include?(key)
          error! "You have no permission to submit changelogs for this artifact!", 403
        end

        datafile  = ActionDispatch::Http::UploadedFile.new( params[:scm_changes_file] )
        file_name = datafile.original_filename
        content   = datafile.read
        parser    = ScmChangelogParser.new
        changes   = parser.parse content
        changes.each do |change|
          change.language = product.language
          change.prod_key = product.prod_key
          change.version  = decode_prod_key params[:prod_version]
          change.save
        end

        {success: true, message: 'Changes parsed and saved successfully.'}
      end


      desc "suggest a license for an artifact", {
        detail: %q[With this endpoint users can suggest a license for an artifact.]
        }
      params do
        requires :lang          , :type => String, :desc => %Q[ programming language ]
        requires :prod_key      , :type => String, :desc => %Q{ product key }
        requires :prod_version  , :type => String, :desc => %Q[ product version ]
        requires :license_name  , :type => String, :desc => %Q[ name of the license ]
        requires :license_source, :type => String, :desc => %Q[ source of the license. Where did you find it? ]
        optional :comments      , :type => String, :desc => %Q[ you wanna say anyting important to this license? ]
      end
      post '/:lang/:prod_key/:prod_version/license' do
        authorized?

        product = fetch_product(params[:lang], params[:prod_key])
        ls = LicenseSuggestion.new({ :language => product.language,
                                     :prod_key => product.prod_key,
                                     :version  => decode_prod_key( params[:prod_version] ),
                                     :name     => params[:license_name],
                                     :url      => params[:license_source],
                                     :comments => params[:comments] })
        ls.user         = current_user
        ls.organisation = current_orga
        if ls.save == false
          error! "Something went wrong! #{ls.errors.full_messages.to_sentence}!", 403
        end

        LicenseMailer.new_license_suggestion(ls).deliver_now

        {success: true, message: 'Your suggestion was saved successfully and will be reviewed soon!'}
      end


    end # resource products

  end # class

end # end module
