require 'spec_helper'
require 'byebug'

module Spree
  describe MercadoPagoController, type: :controller do
    include Devise::TestHelpers 

    describe "#ipn" do
      let(:operation_id) { "op123" }

      describe "for valid notifications" do
        let(:use_case) { double("use_case") }

        it "handles notification and returns success" do
          MercadoPago::HandleReceivedNotification.should_receive(:new).and_return(use_case)
          use_case.should_receive(:process!)

          spree_post :ipn, { id: operation_id, topic: "payment" }
          expect(response.success?).to be true

          notification = ::MercadoPago::Notification.order(:created_at).last
          notification.topic.should eq("payment")
          notification.operation_id.should eq(operation_id)
        end
      end

      describe "for invalid notification" do
        it "responds with 200 OK" do
          spree_post :ipn, { id: operation_id, topic: "nonexistent_topic" }
          expect(response.bad_request?).to be false
        end
      end
    end

    describe "#success" do
      let(:user){ create(:user) }
      let(:order){ create(:completed_order_with_pending_payment, user: user) }
      let(:payment){ create(:payment, amount: order.total, number: 'PXFLWU8U', state: 'completed') }
      let(:payment_2){ create(:payment, amount: order.total, number: 'YXTLWU8U', state: 'pending') }

      it "updates payment state and shows a success message" do
        order.payments = []
        order.payments << payment

        spree_post :success, { collection_status: "approved", external_reference: 'PXFLWU8U' }
        expect(flash[:notice]).to eq Spree.t(:order_processed_successfully)
      end

      it "doesn't update state pending for pending payment" do
        order.payments = []
        order.payments << payment_2
        payment = payment_2

        spree_post :success, { collection_status: "pending", external_reference: 'YXTLWU8U' }
        expect(flash[:notice]).to eq Spree.t(:payment_processing_pending)
      end
    end
  end
end
