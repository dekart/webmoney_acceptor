Webmoney Acceptor
======================

Small controller & view extension to ease WebMoney (http://merchant.webmoney.ru/)
payment processing.

Usage
-----

1) Configure your wallet in the config/webmoney.yml file:

    development:
      wallet: "R123456789012"
      secret: "mysupersecret123"

2) Add new action to your payment controller:

    class PaymentsController < ApplicationController
      # Disable forgery protection for webmoney accepting action
      skip_before_filter :verify_authenticity_token, :only => :webmoney_payment

      def webmoney_payment
        @payment = current_user.payments.build(
          :currency => webmoney.currency,
          :amount   => webmoney.params[:payment_amount]
        )

        if webmoney.prerequest? # Pre-request to check that your site is available
          if @payment.valid?
            render :text => "YES"
          else
            render :text => @payment.errors.full_messages.join("; ")
          end
        elsif webmoney.valid_payment? # Payment callback
          if @payment.save
            render :text => "Success"
          else
            Rails.logger.error("Webmoney payment error!")

            render :text => "failure"
          end
        else # Payment invalid
          raise WebmoneyAcceptor::InvalidTransaction
        end
      end
    end

  *Important:* Payment model is not provided by the plugin. You should create it by yourself.

3) Add acction to your routes:

    ActionController::Routing::Routes.draw do |map|
      ...

      map.resources :payments, :collection => {:webmoney_payment => :post}

      ...
    end

4) Add WebMoney payment form to your view:

    <% webmoney_payment_form(@amount, :payment_desc => "This is your payment description") do %>
      Confirmation text goes here

      <%= submit_tag("Pay") %>
    <% end %>

5) Profit! :)

Avanced Usage
-------------

You can use multiple wallets to accept payments. The only thing you should do
for this is to provide wallet and secret to form and validation method.

In your view:

    <% webmoney_payment_form("Z123456789012", @amount) do %>
      ...
    <% end %>

In your controller:

    def webmoney_payment
      ...

      if webmoney.prerequest?
        ...
      elsif webmoney.valid_payment?("mycustomsecret123")
        ...
      end
    end

Some additional methods that can be useful:

* *webmoney.currency* - currently used WebMoney currency (:wmr, :wmz, etc)
* *webmoney.params* - a hash of WebMoney-related params (all params that start with "LMI_")

Testing
-------

No tests yet :( You can fork this plugin at GitHub (http://github.com/dekart/webmoney_acceptor)
and add your own tests. I'll be happy to accept patches!

Installing the plugin
------------------

    ./script/plugin install git://github.com/dekart/webmoney_acceptor.git

Credits
-------

Written by Alex Dmitriev (http://railorz.ru)
