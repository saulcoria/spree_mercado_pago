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
      
      #SE DESCUENTA EL STOCK MOMENTANEAMENTE Y CUANDO SE FINALIZA EL PAGO SE VUELVE A SUBIR
      if(check_stock)
        redirect_to provider.redirect_url
      else
        flash.notice = Spree.t(:OUT_OF_STOCK)
        flash['order_completed'] = false
        redirect_to spree.cart_path
      end
    end

    # Success/pending callbacks are currently aliases, this may change
    # if required.
    def success
		if params["collection_status"] == "approved"
            restore_stock
			payment.complete!
			payment.order.next
			flash.notice = Spree.t(:order_processed_successfully)
			flash['order_completed'] = true
		end
		
		if params["collection_status"] == "pending"
            restore_stock
			payment.pend!
			payment.order.next
			flash.notice = Spree.t(:payment_processing_pending)
			flash['order_completed'] = false
		end

		redirect_to spree.order_path(payment.order)
    end

    def failure
        restore_stock
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

        notification = MercadoPago::Notification.
                       new(operation_id: params[:id], topic: params[:topic])

        if notification.save
          begin
            MercadoPago::HandleReceivedNotification.new(notification).process!
          rescue Exception => a
            logger.debug("Error al procesar la notificación.")
            logger.debug("Error: #{a.to_s}")
          end
        end

        logger.info("Notificacion procesada correctamente")
        logger.info("--------------------")
        logger.info("Devolviendo STATUS 200 OK")
      rescue Exception => e
        logger.debug("Error al procesar la notificación")
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
      
      def check_stock
        
		  if current_order.ensure_line_items_are_in_stock then
			current_order.line_items.each do |item|
          		flgDescontoStock = false
          		item.variant.stock_items.each do |stock_item|
              	#PREGUNTO POR LAS DUDAS QUE HAYA MAS DE UN STOCK ITEM POR VARIANTE
					if stock_item.count_on_hand >= item.quantity && flgDescontoStock == false then
						stock_item.set_count_on_hand(stock_item.count_on_hand - item.quantity)
						flgDescontoStock = true
					end
				end
			end
          else
            return false
          end
      end
    
    def restore_stock
      current_order.line_items.each do |item|
        flgDescontoStock = false
        
        item.variant.stock_items.each do |stock_item|
          #PREGUNTO POR LAS DUDAS QUE HAYA MAS DE UN STOCK ITEM POR VARIANTE
          if flgDescontoStock == false
            stock_item.set_count_on_hand(stock_item.count_on_hand + item.quantity)
            flgDescontoStock = true
            break
          end
        end
        
      end
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
