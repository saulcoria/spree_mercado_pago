# Process notification:
# ---------------------
# Fetch collection information
# Find payment by external reference
# If found
#   Update payment status
#   Notify user
# If not found
#   Ignore notification (maybe payment from outside Spree)

require 'byebug'
module MercadoPago
  class ProcessNotification
    # Equivalent payment states
    # MP state => Spree state
    # =======================
    #
    # approved     => complete
    # pending      => pend
    # in_process   => pend
    # rejected     => failed
    # refunded     => void
    # cancelled    => void
    # in_mediation => pend
    # charged_back => void
    STATES = {
      complete: %w(approved),
      failure: %w(rejected),
      void:    %w(refunded cancelled charged_back),
      pending: %w(pending in_process in_mediation)
    }

    attr_reader :notification

    def initialize(notification)
      @notification = notification
    end

    def process!
      # Fix: Payment method is an instance of Spree::PaymentMethod::MercadoPago not THE class
      client = ::Spree::PaymentMethod.where(type: "Spree::PaymentMethod::MercadoPago").first.provider
      if notification.topic == "merchant_order"
        merchant_info = client.get_operation_info(notification.operation_id,notification.topic)
        if merchant_info["payments"] == []
          payment = Spree::Payment.where(identifier: merchant_info["external_reference"]).first
          payment.pend
          payment.order.updater.update
          payment.order.next
        else
          payments = merchant_info["payments"]
          approved_payments = payments.select {|p| STATES[:complete].include?(p["status"]) }
          failure_payments = payments.select {|p| STATES[:failure].include?(p["status"]) }
          void_payments = payments.select {|p| STATES[:void].include?(p["status"]) }
          pending_payments = payments.select {|p| STATES[:pending].include?(p["status"])} 

          if payment = Spree::Payment.where(number: merchant_info["external_reference"]).first
            if approved_payments.size > 0
              payment.complete
            elsif failure_payments.size > 0
              payment.failure 
            elsif void_payments.size > 0
              payment.void
            elsif pending_payments.size > 0
              payment.pend
            else
              payment.pend
            end
          end
        end
      elsif notification.topic == "payment"
        op_info = client.get_operation_info(notification.operation_id,notification.topic)["collection"]
        if payment = Spree::Payment.where(number: op_info["external_reference"]).first
          if STATES[:complete].include?(op_info["status"])
            payment.complete
          elsif STATES[:failure].include?(op_info["status"])
            payment.failure
          elsif STATES[:void].include?(op_info["status"])
            payment.void
          elsif STATES[:pending].include?(op_info["status"])
            payment.pend
          end
        end
      end

      payment.order.updater.update
      payment.order.next
    end
  end
end
