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
  jQuery('#go_to_confirm').bind('click',function(){goToMercadoPago()});  
}

function bindMercadoPagoPaymentMethod(){
  jQuery("#payment-method-fields li label [data-gateway='Spree::PaymentMethod::MercadoPago']").click(bindMercadoPagoPaymentButton);  
}

function goToMercadoPago(){
    var coupon_code, coupon_code_field, coupon_status, url;

    coupon_code_field = $('#order_coupon_code');

    coupon_code = $.trim(coupon_code_field.val());

    if (coupon_code !== '') {
        if ($('#coupon_status').length === 0) {
            coupon_status = $("<div id='coupon_status'></div>");
            coupon_code_field.parent().append(coupon_status);
        } 

        coupon_status = $("#coupon_status");
        url = Spree.url(Spree.routes.apply_coupon_code(Spree.current_order_id), {
            order_token: Spree.current_order_token,
            coupon_code: coupon_code
        });
        coupon_status.removeClass();
        $.ajax({
            async: false,
            method: "PUT",
            url: url,
            success: function(data) {
                coupon_code_field.val('');
                setTimeout(function(){
                    coupon_status.fadeOut("500");
                },2000);
                coupon_status.addClass("alert-success cupon-checkout").html("Cupón aplicado correctamente");
                coupon_status.fadeIn("fast");
                jQuery('#btnMercadoPago').click();
            },
            error: function(xhr) {
                var handler;
                handler = JSON.parse(xhr.responseText);

                setTimeout(function(){
                    coupon_status.fadeOut("500");
                },5000);
                coupon_status.addClass("alert-error cupon-checkout").html(handler["error"]);
                coupon_status.fadeIn("fast");
                $('.continue').attr('disabled', false);
                return false;
            }
        });
    } else {
        jQuery('#btnMercadoPago').click();
    }
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
