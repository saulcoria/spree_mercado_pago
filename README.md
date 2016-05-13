Spree Mercado Pago Payment Method
=================================

Integration of Mercado Pago with Spree 2.3 and 2.4
  
For Spree 1.2 - Take a look a 3-0-stable branch

Installation
------------

```
gem 'spree_mercado_pago', git: "git@gitlab.com.ar:spree-extensions/spree_mercado_pago.git", :branch => 'master'  (or another branch-name).
```

inside your project run

```
bundle exec rails g spree_mercado_pago:install
```

to import assets and migrations.

Usage
-----

- Add a new payment method in the admin panel of type Spree::PaymentMethod::MercadoPago
- After adding the payment method you will be able to configure your Client ID and Client Secret (provided by Mercado Pago).

IPN
---

For IPN you need to configure the notification URL in Mercado Pago's site. The notification URL will be `http[s]://[your_domain]/mercado_pago/ipn`. Please review Mercado Pago's documentation at http://developers.mercadopago.com/ for the correct place where to configure IPN notification URLs.


Pending Work
------------

- Configurable currency

Testing
-------

- clone this repo
- execute `bundle`
- execute `rake test_app` to build a dummy app directory inside specs
- execute `bundle exec rspec spec`
