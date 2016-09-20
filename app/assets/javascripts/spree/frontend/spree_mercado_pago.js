//= require spree/frontend
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

function bindMercadoPagoPaymentButton(){
    $('#go_to_confirm').attr('type','submit');

    $("#payment-method-fields li").each(
        function(){
            if(($(this).find('label').text().match(/^\s+Mercado Pago\s+$/)) && ($(this).find('input').is(":checked"))){
                $('#go_to_confirm').bind('click',function(){});
                $('#go_to_confirm').attr('type','button');
                $('#go_to_confirm').bind('click',$('#btnMercadoPago').click());
            }
        }
    ); 
}

jQuery(document).ready(function() {
  checkedPaymentMethod = jQuery('#order_payments_attributes__payment_method_id');
  MercadoPago.hidePaymentSaveAndContinueButton(checkedPaymentMethod);
  paymentMethods = jQuery('#order_payments_attributes__payment_method_id').click(function (e) {
    MercadoPago.hidePaymentSaveAndContinueButton($(e.target));
  });
  jQuery('button.mercado_pago_button').click(function(event){
    jQuery(event.target).prop("disabled",true);
  });
});
