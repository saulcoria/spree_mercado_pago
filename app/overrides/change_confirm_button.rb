Deface::Override.new(:virtual_path => 'spree/checkout/forms/_payment',
                                          :name => 'change_confirm_button',
                                          :insert_after => "div.text-right.form-buttons[data-hook='buttons']", 
                                                               :template => 'spree/checkout/bind_mercado_pago.erb'
                    )
