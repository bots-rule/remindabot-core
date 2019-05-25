require 'sinatra'
require 'octokit'
require 'dotenv/load' # Manages environment variables
require 'json'
require 'openssl'     # Verifies the webhook signature
require 'logger'      # Logs debug statements

require_relative 'helpers/init'

set :port, 3000
set :bind, '0.0.0.0'

class GHAapp < Sinatra::Application

  # Turn on Sinatra's verbose logging during development
  configure :development do
    set :logging, Logger::DEBUG
  end

  # Configure the homepage
  get '/' do
    'Nothing here, you don\'t need to visit this url manually.'
  end

  # Executed before each request to the `/event_handler` route
  before '/event_handler' do
    get_payload_request(request)
    verify_webhook_signature
    authenticate_app
    # Authenticate the app installation in order to run API operations
    authenticate_installation(@payload)
  end

  # The event handler
  post '/event_handler' do
    case request.env['HTTP_X_GITHUB_EVENT']
    when 'issue_comment'
      if @payload['action'] === 'created'
        handle_comment_created_event(@payload)
      end
      if @payload['action'] === 'deleted'
        handle_comment_deleted_event(@payload)
      end
    end
    200 # success status
  end


  helpers do
    # Register helper methods imported from helpers/init
    GHAapp.helpers GithubHelper
    GHAapp.helpers EventHandlers

    # Saves the raw payload and converts the payload to JSON format
    def get_payload_request(request)
      # request.body is an IO or StringIO object
      # Rewind in case someone already read it
      request.body.rewind
      # The raw text of the body is required for webhook signature verification
      @payload_raw = request.body.read
      begin
        @payload = JSON.parse @payload_raw
      rescue => e
        fail  "Invalid JSON (#{e}): #{@payload_raw}"
      end
    end

  end

  # Finally some logic to let us run this server directly from the command line,
  # or with Rack. Don't worry too much about this code. But, for the curious:
  # $0 is the executed file
  # __FILE__ is the current file
  # If they are the same—that is, we are running this file directly, call the
  # Sinatra run method
  run! if __FILE__ == $0
end
