require 'spec_helper'

describe "OrderPreferencesBuilder" do
  # Factory order_with_line_items is incredibly slow..
  let(:order) do
    order = create(:order)
    create_list(:line_item, 2, order: order)
    order.line_items.reload
    order.update!
    order
  end

  let(:payment)       { create(:payment) }
  let(:callback_urls) { {success: "http://example.com/success", pending: "http://example.com/pending", failure: "http://example.com/failure"} }
  let(:payer_data)    { create(:address, dni: 23987221) }

  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  include Spree::ProductsHelper

  context "Calling preferences_hash" do
    subject { MercadoPago::OrderPreferencesBuilder.new(order, payment, callback_urls, payer_data).preferences_hash }

    it "should return external reference" do
      expect(subject).to include(external_reference:payment.number)
    end

    it "should set callback urls" do
      expect(subject).to include(back_urls:callback_urls)
    end

    it "should set payer data if brought" do
      hs_payer_data = {
        :name => payer_data.firstname,
        :surname => payer_data.lastname,
        :email => order.user.email,
        :phone => {
          :area_code => '54',
          :number => payer_data.phone.to_s
        },
        :identification => {
          :type => 'DNI',
          :number => payer_data.dni.to_s
        },
        :address => {
          :zip_code => payer_data.zipcode.to_s,
          :street_name => payer_data.address1,
          :street_number => payer_data.address2.to_i
        },
        :date_created => order.user.created_at.iso8601
      }

      expect(subject).to include(payer: hs_payer_data)
    end

    it "should set an item for every line item" do
      expect(subject).to include(:items)

      order.line_items.each do |line_item|
        expect(subject[:items]).to include({
          title: line_item_description_text(line_item.variant.product.name),
          unit_price: line_item.price.to_f,
          quantity: line_item.quantity.to_f,
          currency_id: "ARS"
        })
      end
    end

    context "for order with adjustments" do
      let!(:adjustment) { Spree::Adjustment.create!(adjustable: order, order: order, label: "Descuento", amount: -10.0) }

      it "should set its adjustments as items" do
        expect(subject[:items]).to include({
          title: line_item_description_text(adjustment.label),
          unit_price: adjustment.amount.to_f,
          quantity: 1,
          currency_id: "ARS"
        })
      end

      it "should only have line items and adjustments in items" do
        expect(subject[:items].size).to eq(order.line_items.count + order.adjustments.count)
      end
    end
  end
end
