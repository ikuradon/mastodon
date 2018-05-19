# frozen_string_literal: true

class ActivityPub::DeliveryWorker
  include Sidekiq::Worker

  STOPLIGHT_FAILURE_THRESHOLD = 10
  STOPLIGHT_COOLDOWN = 60

  sidekiq_options queue: 'push', retry: 16, dead: false

  HEADERS = { 'Content-Type' => 'application/activity+json' }.freeze

  def perform(json, source_account_id, inbox_url)
    @json           = json
    @source_account = Account.find(source_account_id)
    @inbox_url      = inbox_url

    perform_request

    failure_tracker.track_success!
  rescue => e
    failure_tracker.track_failure!
    raise e.class, "Delivery failed for #{inbox_url}: #{e.message}", e.backtrace[0]
  end

  private

  def build_request
    request = Request.new(:post, @inbox_url, body: @json)
    request.on_behalf_of(@source_account, :uri)
    request.add_headers(HEADERS)
  end

  def perform_request
    light = Stoplight(@inbox_url) do
      build_request.perform do |response|
        raise Mastodon::UnexpectedResponseError, response unless response_successful?(response) || response_error_unsalvageable?(response)
      end
    end

    light.with_threshold(STOPLIGHT_FAILURE_THRESHOLD)
         .with_cool_off_time(STOPLIGHT_COOLDOWN)
         .run
  end

  def response_successful?(response)
    response.code > 199 && response.code < 300
  end

  def response_error_unsalvageable?(response)
    response.code > 399 && response.code < 500 && response.code != 429
  end

  def failure_tracker
    @failure_tracker ||= DeliveryFailureTracker.new(@inbox_url)
  end
end
