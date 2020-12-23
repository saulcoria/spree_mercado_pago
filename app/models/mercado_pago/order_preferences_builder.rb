module MercadoPago
  class OrderPreferencesBuilder
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::SanitizeHelper
    include Spree::ProductsHelper

    def initialize(order, payment, callback_urls, payer_data = nil)
      @order         = order
      @payment       = payment
      @callback_urls = callback_urls
      @payer_data    = payer_data
    end

    def preferences_hash
      {
        external_reference: @payment.number,
        back_urls: @callback_urls,
        payer: generate_payer_data,
        items: generate_items
      }
    end

    private

    def generate_items
      items = []

      items += generate_items_from_line_items
      items += generate_items_from_adjustments
      items += generate_items_from_shipments
      items[0][:unit_price] += @order.promo_total.to_f

      items
    end

    def generate_items_from_shipments
      @order.shipments.collect do |shipment|
        {
          :title => shipment.shipping_method.name,
          :unit_price => shipment.cost.to_f,
          :quantity => 1,
          :currency_id => 'ARS'
        }
      end
    end

    def generate_items_from_line_items
      @order.line_items.collect do |line_item|
        {
          :title => line_item_description_text(line_item.variant.product.name),
          :unit_price => line_item.price.to_f,
          :quantity => line_item.quantity,
          :currency_id => 'ARS'
        }
      end
    end

    def generate_items_from_adjustments
      @order.adjustments.eligible.collect do |adjustment|
        {
          title: line_item_description_text(adjustment.label),
          unit_price: adjustment.amount.to_f,
          quantity: 1,
          currency_id: "ARS"
        }
      end
    end

    def generate_payer_data
      {
        :name => @payer_data.firstname,
        :surname => @payer_data.lastname,
        :email => @order.user ? @order.user.email : @order.email,
        :phone => {
          :area_code => '54',
          :number => @payer_data.phone.to_s
        },
        :identification => {
          :type => 'DNI',
          :number => @payer_data.dni.to_s
        },
        :address => {
          :zip_code => @payer_data.zipcode.to_s,
          :street_name => @payer_data.address1,
          :street_number => @payer_data.address2.to_i
        },
        :date_created => @order.user ? @order.user.created_at.iso8601 : @order.created_at.iso8601
      }
    end
  end
end
