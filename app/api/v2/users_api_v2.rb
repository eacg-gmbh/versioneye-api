require 'grape'
require 'entities_v2'

require_relative 'helpers/session_helpers.rb'
require_relative 'helpers/paging_helpers.rb'
require_relative 'helpers/user_helpers.rb'

module V2
  class UsersApiV2 < Grape::API
    helpers SessionHelpers
    helpers PagingHelpers
    helpers UserHelpers

    resource :me do
      before do
        rate_limit
        track_apikey
      end

      desc "shows profile of authorized user", {
        detail: %q[On Swagger, you can create session by adding additional parameter :api_key.]
      }
      get do
        authorized?

        orga = current_orga
        if orga
          api = orga.api
          me = Me.new
          me.update_from_orga( orga )
          me.enterprise_projects = api.enterprise_projects
          me.rate_limit          = api.rate_limit
          me.comp_limit          = api.comp_limit
          me.active              = api.active
        else
          api = Api.by_user( @current_user )
          me = Me.new
          me.update_from_user( @current_user )
          me.enterprise_projects = api.enterprise_projects
          me.rate_limit          = api.rate_limit
          me.comp_limit          = api.comp_limit
          me.active              = api.active
          me.notifications = {
            :new => Notification.by_user_id(@current_user.id).all_not_sent.count,
            :total => Notification.by_user_id(@current_user.id).count
          }
        end

        present me, with: EntitiesV2::UserDetailedEntity
      end


      desc "shows the packages you are following"
      params do
        optional :page, type: Integer, desc: "page number for pagination"
      end
      get '/favorites' do
        authorized?
        if @current_user.nil?
          error! "This API Endpoint requires the API key of a user, not an organisation.", 403
        end

        make_favorite_response(@current_user, params[:page], 30)
      end


      desc "shows comments of authorized user"
      params do
        optional :page, type: Integer, desc: "page number for pagination"
      end
      get '/comments' do
        authorized?
        if @current_user.nil?
          error! "This API Endpoint requires the API key of a user, not an organisation.", 403
        end

        make_comment_response(@current_user, params[:page], 30)
      end


      desc "shows unread notifications of authorized user", {
        detail: %q[
This Endpoint returns the 30 latest notifications.

If there are new versions out there for software packages you follow directly on VersionEye, then
each new version is a new **notification** for your account.
        ]
      }
      params do
        optional :page, :type => Integer, :desc => "Specify page for paging", :regexp => /^[\d]+$/
      end
      get '/notifications' do
        authorized?
        if @current_user.nil?
          error! "This API Endpoint requires the API key of a user, not an organisation.", 403
        end

        page = params[:page]
        page = 1 if page.to_i < 1
        unread_notifications = Notification.by_user( @current_user ).desc(:created_at).paginate(per_page: 30, :page => page.to_i)
        notifications = []
        unread_notifications.each do |noti|
          ndd = NotificationDetailDto.new
          ndd.created_at = noti.created_at
          ndd.version_id = noti.version_id
          ndd.sent_email = noti.sent_email
          ndd.product_id = noti.product_id
          ndd.read       = noti.read
          notifications << ndd

          noti.read = true
          noti.save
        end

        temp_notice = NotificationDto.new # Grape can't handle plain Hashs w.o to_json
        temp_notice.user_info     = @current_user
        temp_notice.unread        = Notification.by_user( @current_user ).where(:read => false).count
        temp_notice.notifications = notifications

        present temp_notice, with: EntitiesV2::UserNotificationEntity
      end
    end


    resource :users do
      before do
        track_apikey
      end

      desc "shows profile of given user_id"
      params do
        requires :username, :type => String, :desc => "username"
      end
      get '/:username' do
        authorized?
        @user = User.find_by_username(params[:username])
        present @user, with: EntitiesV2::UserEntity
      end

      desc "shows user's favorite packages"
      params do
        requires :username, :type => String, :desc => "username"
        optional :page, :type => Integer, :desc => "Pagination number"
      end
      get '/:username/favorites' do
        authorized?
        @user = User.find_by_username(params[:username])
        error!("User with username `#{params[:username]}` doesn't exists.", 400) if @user.nil?

        make_favorite_response(@user, params[:page], 30)
      end

      desc "shows user's comments"
      params do
        requires :username, type: String, desc: "VersionEye users' nickname"
        optional :page, type: Integer, desc: "pagination number"
      end
      get '/:username/comments' do
        authorized?

        @user = User.find_by_username params[:username]
        error!("User #{params[:username]} don't exists", 400) if @user.nil?

        make_comment_response(@user, params[:page], 30)
      end
    end
  end
end
