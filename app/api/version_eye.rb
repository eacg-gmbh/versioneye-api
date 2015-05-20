require 'grape'

module VersionEye
	class API < Grape::API
		mount V2::ApiV2 => '/v2'
	end
end