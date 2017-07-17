require 'rest_client'
require 'mercado_pago/client/authentication'
require 'mercado_pago/client/preferences'
require 'mercado_pago/client/api'

module MercadoPago
  class Client
    # These three includes are because of the user of line_item_description from
    # ProductsHelper
    include Authentication
    include Preferences
    include API

    attr_reader :errors
    attr_reader :auth_response
    attr_reader :preferences_response

    def initialize(payment_method, options={})
      @logger = Logger.new("#{Rails.root}/log/ipn_notifications.log", 'daily') 
      @payment_method = payment_method
      @api_options    = options.clone
      @errors         = []
    end

    def get_operation_info(operation_id, topic)
      if topic == "merchant_order"
        url = create_url(merchant_orders_url(operation_id), access_token: access_token)
      else #payment
        url = create_url(notifications_url(operation_id), access_token: access_token)
      end
      
      options = {content_type: 'application/x-www-form-urlencoded', accept: 'application/json'}

      @logger.debug("Url de api de solicitud de información de pago:.....#{url}......")
      get(url, options)
    end

    def get_payment_status(external_reference)
      response = send_payments_request({external_reference: external_reference, access_token: access_token})

      if response['results'].empty?
        "no_response"
      else
        response['results'][0]['status']
      end
    end

    private

    def log_error(msg, response, request, result)
      Rails.logger.info msg
      Rails.logger.info "response: #{response}."
      Rails.logger.info "request args: #{request.args}."
      Rails.logger.info "result #{result}."
    end

    def send_search_request(params, options={})
      url = create_url(search_url, params)
      options = {content_type: 'application/x-www-form-urlencoded', accept: 'application/json'}
      get(url, options)
    end

    def send_payments_request(params, options={})
      url = create_url(payments_url, params)
      options = {content_type: 'application/x-www-form-urlencoded', accept: 'application/json'}
      get(url, options)
    end
  end
end
