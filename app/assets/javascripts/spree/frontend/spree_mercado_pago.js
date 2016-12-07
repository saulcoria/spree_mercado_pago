MercadoPago = {
  hidePaymentSaveAndContinueButton: function(paymentMethod) {
    if (MercadoPago.paymentMethodID && paymentMethod.val() == MercadoPago.paymentMethodID) {
      jQuery('.continue').hide();
      jQuery('[data-hook=coupon_code]').hide();
    } else {
      jQuery('.continue').show();
      jQuery('[data-hook=coupon_code]').show();
    }
  }
};

function bindMercadoPagoPaymentButton() {
  jQuery('#go_to_confirm').unbind('click');
  jQuery('#go_to_confirm').attr('type','button');
  jQuery('#go_to_confirm').bind('click',function(){jQuery('#btnMercadoPago').click()});  
}

function bindMercadoPagoPaymentMethod(){
  jQuery("#payment-method-fields li label [data-gateway='Spree::PaymentMethod::MercadoPago']").click(bindMercadoPagoPaymentButton);  
}

jQuery(document).ready(function() {
  checkedPaymentMethod = jQuery('#order_payments_attributes__payment_method_id');
  MercadoPago.hidePaymentSaveAndContinueButton(checkedPaymentMethod);
  paymentMethods = jQuery('#order_payments_attributes__payment_method_id').click(function (e) {
    MercadoPago.hidePaymentSaveAndContinueButton(jQuery(e.target));
  });
  jQuery('button.mercado_pago_button').click(function(event){
    jQuery(event.target).prop("disabled",true);
  });

});
