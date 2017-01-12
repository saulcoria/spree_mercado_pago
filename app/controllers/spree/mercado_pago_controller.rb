module Spree
  class MercadoPagoController < StoreController
    protect_from_forgery except: :ipn
    skip_before_filter :set_current_order, only: :ipn

    def checkout
      if current_order.state_name != :payment 
        redirect_to spree.cart_path and return false
      end

      payment_method = PaymentMethod::MercadoPago.find(params[:payment_method_id])
      payment = current_order.payments.create!({amount: current_order.total, payment_method: payment_method})
      payment.started_processing!

      preferences = ::MercadoPago::OrderPreferencesBuilder.new(current_order, payment, callback_urls).preferences_hash

      provider = payment_method.provider
      provider.create_preferences(preferences)

      redirect_to provider.redirect_url
    end

    # Success/pending callbacks are currently aliases, this may change
    # if required.
    def success
      if params["collection_status"] == "approved"
        payment.complete!
        payment.order.next
        flash.notice = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
      end

      if params["collection_status"] == "pending"
        payment.pend!
        payment.order.next
        flash.notice = Spree.t(:payment_processing_pending)
        flash['order_completed'] = false
      end

      redirect_to spree.order_path(payment.order)
    end

    def failure
      payment.failure!
      flash.alert = Spree.t(:payment_processing_failed)
      flash['order_completed'] = false
      redirect_to spree.cart_path
    end

    def ipn
      begin
        logger = Logger.new("#{Rails.root}/log/ipn_notifications.log", 'daily')
        logger.info("-----------------------------------------")
        logger.info("Iniciando recepción de notificaciones IPN")
        logger.info("--------------------")
        logger.info("Datos de la operacion:...Operation id:...#{params[:id]}....Topic:...#{params[:topic]}....")
        logger.info("Datos de los parametros:...params...#{params}...")
        logger.info("Datos de la request:..URL:..#{request.url}..POST:..#{request.post?}...")

        notification = MercadoPago::Notification.
          new(operation_id: params[:id], topic: params[:topic])

        if notification.save
          begin
            MercadoPago::HandleReceivedNotification.new(notification).process!
            logger.info("Notificacion procesada correctamente")
          rescue Exception => a
            logger.debug("Error al procesar la notificación.")
            logger.debug("Error: #{a.to_s}")
            logger.debug("Error: #{a.backtrace.to_s}")
          end
        end

        logger.info("--------------------")
        logger.info("Devolviendo STATUS 200 OK")
      rescue Exception => e
        logger.debug("Error al guardar la notificación")
        logger.debug("Error: #{e.to_s}")
        logger.info("--------------------")

        logger.info("Devolviendo igualmente, STATUS 200 OK")
      end
      logger.info("-----------------------------------------")

      render nothing: true, status: 200, content_type: "text/html"
    end

    private

    def payment
      @payment ||= Spree::Payment.where(number: params[:external_reference]).
        first
    end

    def callback_urls
      @callback_urls ||= {
        success: mercado_pago_success_url,
        pending: mercado_pago_success_url,
        failure: mercado_pago_failure_url
      }
    end
  end
end
