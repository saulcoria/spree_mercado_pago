require 'json'

class MercadoPago::Client
  module API
    def redirect_url
      point_key = sandbox ? 'sandbox_init_point' : 'init_point'
      @preferences_response[point_key]
    end

    private

    def merchant_orders_url(operation_id)
      sandbox_part = sandbox ? 'sandbox/' : ''
      "https://api.mercadolibre.com/#{sandbox_part}merchant_orders/#{operation_id}"
    end

    def notifications_url(operation_id)
      @logger ||=  Logger.new("#{Rails.root}/log/ipn_notifications.log", 'daily')
      sandbox_part = sandbox ? 'sandbox/' : ''

      @logger.info("Url de notificación:.....https://api.mercadolibre.com/#{sandbox_part}collections/notifications/#{operation_id}..........")
      "https://api.mercadolibre.com/#{sandbox_part}collections/notifications/#{operation_id}"
    end

    def search_url
      sandbox_part = sandbox ? 'sandbox/' : ''
      "https://api.mercadolibre.com/#{sandbox_part}collections/search"
    end

    def payments_url
      sandbox_part = sandbox ? 'sandbox/' : ''
      "https://api.mercadopago.com/#{sandbox_part}v1/payments/search"
    end

    def create_url(url, params={})
      uri = URI(url)
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end

    def preferences_url(token)
      create_url('https://api.mercadolibre.com/checkout/preferences', access_token: token)
    end

    def sandbox
      @api_options[:sandbox]
    end

    def get(url, request_options={}, options={})
      response = RestClient.get(url, request_options)
      JSON.parse(response)
    rescue => e
      logger = Logger.new("#{Rails.root}/log/ipn_notifications.log", 'daily')
      logger.info("Error en get....#{e.to_s}....")
      logger.info("Backtrace en get....#{e.backtrace.to_s}....")
      raise e unless options[:quiet]
    end
  end
end
