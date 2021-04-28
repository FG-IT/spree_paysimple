require 'paysimple'
module Spree
  class Gateway::PaySimple < Gateway

    preference :login, :string
    preference :password, :string
    preference :enable_simplejs, :boolean, default: true

    def auto_capture?
      true
    end

    def method_type
      if preferred_enable_simplejs
        'paysimple'
      else
        'gateway'
      end
    end

    def payment_source_class
      if preferred_enable_simplejs
        PaySimpleCheckout
      else
        CreditCard
      end
    end

    def provider_class
      Paysimple
    end

    def payment_profiles_supported
      false
    end

    def provider
      Paysimple.api_user = preferred_login
      Paysimple.api_key = preferred_password
      Paysimple.api_endpoint = preferred_test_mode ? Paysimple::Endpoint::SANDBOX : Paysimple::Endpoint::PRODUCTION
      Paysimple.verify_ssl = false
      Paysimple.use_ssl = false
      provider_class
    end

    def purchase(money_in_cents, source, gateway_options)
      logger.info source
      logger.info gateway_options

      if source.has_attribute? 'payment_token'
        process_token(money_in_cents, source, gateway_options)
      else
        process_card(money_in_cents, source, gateway_options)
      end

    end

    def authorize(money_in_cents, source, gateway_options)
      purchase money_in_cents, source, gateway_options
    end

    def credit(credit_cents, transaction_id, _options)
      begin
        payment = provider::Payment.get(transaction_id)
        logger.info payment[:status]

        if payment[:status] == 'Voided'
          Response.new(true, "Payment already voided")
        elsif voidable(payment[:status])
          void(transaction_id, nil)
        else
          response = provider::Payment.refund(transaction_id)
          success = response[:status] == 'Reversed' ? true : false
          Response.new(success, nil, response)
        end
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        Response.new(false, e.message)
      end
    end

    def void(transaction_id, _data)
      begin
        response = provider::Payment.void(transaction_id)
        success = response[:status] == 'Voided' ? true : false
        Response.new(success, nil, response)
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        Response.new(false, e.message)
      end

    end

    def cancel(response_code)
      credit(nil, response_code, nil)
    end

    private

    def voidable(payment_status)
      %w(Authorized ReversePosted).include? payment_status
    end

    def process_token(money_in_cents, source, gateway_options)
      order, payment = order_data_from_options(gateway_options)
      begin
        payment = provider::Payment.create({
                                               amount: money_in_cents.to_f / 100,
                                               account_id: source.account_id,
                                               payment_token: source.payment_token,
                                               order_id: order.number,
                                               invoice_number: order.number
                                           })
        Response.new(true, nil, payment)
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        Response.new(false, e.message)
      end
    end

    def process_card(money_in_cents, source, gateway_options)
      order, payment = order_data_from_options(gateway_options)
      @utils = Utils.new(self, order)
      customer_data = @utils.get_customer
      customer_id = @utils.fetch_customer_id(customer_data)
      billing_address = @utils.get_address('billing')

      year4 = source.year > 1000 ? source.year : "20#{source.year}"
      month = "%02d" % source.month
      expiration_date = "#{month}/#{year4}"
      # logger.info billing_address[:postal_code]
      begin
        credit_card = provider::CreditCard.create({
                                                      customer_id: customer_id,
                                                      credit_card_number: source.number,
                                                      expiration_date: expiration_date,
                                                      billing_zip_code: billing_address[:postal_code],
                                                      issuer: @utils.detect_issuer(source.number)
                                                  })

        payment = provider::Payment.create({
                                               amount: money_in_cents.to_f / 100,
                                               account_id: credit_card[:id],
                                               order_id: order.number,
                                               cvv: source.verification_value,
                                               invoice_number: order.number
                                           })
        Response.new(true, nil, payment)
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        Response.new(false, e.message)
      end
    end

    def order_data_from_options(options)
      order_number, payment_number = options[:order_id].split('-')
      order = Spree::Order.find_by(number: order_number)
      payment = order.payments.find_by(number: payment_number)
      [order, payment]
    end

  end
end
