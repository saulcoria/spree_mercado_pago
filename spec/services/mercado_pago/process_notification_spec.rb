require 'spec_helper'

module MercadoPago
  describe ProcessNotification do
    let(:mp){ Spree::PaymentMethod.create(name: "Mercado Pago", type: "Spree::PaymentMethod::MercadoPago") }
    let(:shipment){ FactoryGirl.create(:shipment) }
    let(:payment){ create(:payment, amount: 500, payment_method: mp, source_type:"Spree::PaymentMethod::MercadoPago") } 
    let(:order){ FactoryGirl.create(:order, total: 10, payments: [payment], shipments:[shipment]) }

    let(:operation_id) { "op123" }
    let(:notification) { Notification.new(topic: "payment", operation_id: operation_id) }
    let(:operation_info) do
      {
        "collection" => {
          "external_reference" => order.payments.first.number,
          "status" => "approved"
        }
      }
    end

    let(:authentication_info) do
      {"acces_token" => "shasjkhsjkeiejsh"}
    end

    # The first payment method of this kind will be picked by the process task
    before do
      fake_client = double("fake_client")
      fake_payment_method = double("fake_payment_method", provider: fake_client)
      Spree::PaymentMethod::MercadoPago.stub(first: fake_payment_method)
      
      allow_any_instance_of(MercadoPago::Client::Authentication).to receive(:authenticate).and_return(authentication_info)
      allow_any_instance_of(MercadoPago::Client).to receive(:get_operation_info).with(operation_id, "payment").and_return(operation_info)
      payment.pend!
      payment.state.should eq("pending")
    end

    describe "#process!" do
      it "completes payment for approved payment" do
        ProcessNotification.new(notification).process!
        payment.reload
        payment.state.should eq("completed")
      end

      it "fails payment for rejected payment" do
        operation_info["collection"]["status"] = "rejected"
        ProcessNotification.new(notification).process!
        payment.reload
        payment.state.should eq("failed")
      end

      it "voids payment for rejected payment" do
        operation_info["collection"]["status"] = "cancelled"
        ProcessNotification.new(notification).process!
        payment.reload
        payment.state.should eq("void")
      end

      it "pends payment for pending payment" do
        operation_info["collection"]["status"] = "pending"
        ProcessNotification.new(notification).process!
        payment.reload
        payment.state.should eq("pending")
      end

      context "when MP send only merchant topic" do
        let(:notification2) { Notification.new(topic: "merchant_order", operation_id: "123456698") }
        let(:operation_info_merchant) do
          {"id"=> 123456698, "preference_id"=>"234536496-d2cac735-611c-4841-908d-d898da9b0510", "date_created"=>"2017-01-09T15:12:38.000-04:00", "last_updated"=>"2017-01-09T15:14:40.000-04:00", "application_id"=>nil, "status"=>"closed", "site_id"=>"MLA", "payer"=>{"id"=>141896814, "email"=>"macevedo@web-experto.com.ar"}, "collector"=>{"id"=>234536496, "email"=>"info@monumentalhogar.com", "nickname"=>"MONUMENTAL H."}, "sponsor_id"=>nil, "payments"=>[{"id"=>2529720177, "transaction_amount"=>10, "total_paid_amount"=>10, "shipping_cost"=>0, "currency_id"=>"ARS", "status"=>"approved", "status_detail"=>"accredited", "operation_type"=>"regular_payment", "date_approved"=>"2017-01-09T15:14:12.000-04:00", "date_created"=>"2017-01-09T15:14:13.000-04:00", "last_modified"=>"2017-01-09T15:14:12.000-04:00", "amount_refunded"=>0}], "paid_amount"=>10, "refunded_amount"=>0, "shipping_cost"=>0, "cancelled"=>false, "items"=>[{"category_id"=>nil, "currency_id"=>"ARS", "description"=>nil, "id"=>nil, "picture_url"=>nil, "quantity"=>1, "unit_price"=>10, "title"=>"Rack Microodas"}, {"category_id"=>nil, "currency_id"=>"ARS", "description"=>nil, "id"=>nil, "picture_url"=>nil, "quantity"=>1, "unit_price"=>0, "title"=>"Retiro en Sucursal"}], "marketplace"=>"NONE", "shipments"=>[], "external_reference"=>order.payments.first.number, "additional_info"=>nil, "notification_url"=>nil, "total_amount"=>10} 
        end

        before (:each) do
          allow_any_instance_of(MercadoPago::Client::Authentication).to receive(:authenticate).and_return(authentication_info)
          allow_any_instance_of(MercadoPago::Client).to receive(:get_operation_info).with("123456698","merchant_order").and_return(operation_info_merchant)
          payment.pend! if payment.state != "pending"
          payment.state.should eq("pending")
        end

        it "completes payment for approved payment" do
          ProcessNotification.new(notification2).process!
          payment.reload
          payment.state.should eq("completed")
        end


        it "fails payment for rejected payment" do
          operation_info_merchant["payments"][0]["status"] = "rejected"
          ProcessNotification.new(notification2).process!
          payment.reload
          payment.state.should eq("failed")
        end

        it "voids payment for rejected payment" do
          operation_info_merchant["payments"][0]["status"] = "cancelled"
          ProcessNotification.new(notification2).process!
          payment.reload
          payment.state.should eq("void")
        end

        it "pends payment for pending payment" do
          operation_info_merchant["payments"][0]["status"] = "pending"
          ProcessNotification.new(notification2).process!
          payment.reload
          payment.state.should eq("pending")
        end
      end
    end
  end
end
