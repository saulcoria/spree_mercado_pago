require 'spec_helper'

describe "Checkout", type: :feature, inaccessible: true, js: true do
  include_context 'checkout setup'

  context "visitor makes checkout as guest without registration and select Mercado Pago as payment method" do
    before(:each) do
      stock_location.stock_items.update_all(count_on_hand: 1)

      add_mug_to_cart
      click_button Spree.t(:checkout)

      fill_in "order_email", :with => "test@example.com"
      click_on Spree.t(:continue)
    end

    it "should redirect to mercado pago" do
      fill_in_address
      find('#go_to_delivery').click
      wait_for_ajax
      expect(page).to have_selector('#go_to_payment')
      find('#go_to_payment').click
      wait_for_ajax      
      expect(page).to have_selector('#payment-method-fields')
      find('#payment-method-fields li label', :text => 'Mercado Pago').click 
      
      find('#go_to_confirm').click
      expect(page).to have_content("Cancelar y volver al sitio del vendedor")
    end
  end

  def add_mug_to_cart
    visit spree.root_path
    click_link mug.name
    click_button "add-to-cart-button"
  end

  def fill_in_address
    address = "order_bill_address_attributes"
    fill_in "#{address}_firstname", with: "Ryan"
    fill_in "#{address}_lastname", with: "Bigg"
    fill_in "#{address}_dni", with: "39123321"
    fill_in "#{address}_address1", with: "Swan Street"
    fill_in "#{address}_address2", with: "143"
    fill_in "#{address}_city", with: "Richmond"
    select "Santa Fe", from: "#{address}_state_id"
    fill_in "#{address}_zipcode", with: "2345"
    fill_in "#{address}_phone", with: "(555) 555-5555"
  end
end
