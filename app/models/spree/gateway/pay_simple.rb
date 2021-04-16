require 'paysimple'
module Spree
  class Gateway::PaySimple < Gateway
    preference :login, :string
    preference :password, :string

    def auto_capture?
      true
    end

    # def method_type
    #   'paysimple'
    # end

    def provider_class
      Paysimple
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
      order, payment = order_data_from_options(gateway_options)

      @utils = Utils.new(self, order)
      customer_data = @utils.get_customer
      customer_id = @utils.fetch_customer_id(customer_data)
      logger.info("#{customer_id}")
      billing_address = @utils.get_address('billing')
      year4 = source.year > 1000 ? source.year : "20" + source.year

      begin
        credit_card = provider::CreditCard.create({
                                                      customer_id: customer_id,
                                                      credit_card_number: source.number,
                                                      expiration_date: "#{source.month}/#{year4}",
                                                      billing_zip_code: billing_address[:postal_code],
                                                      issuer: @utils.detect_issuer(source.number)
                                                  })
        logger.info "#{credit_card}"

        payment = provider::Payment.create({
                                               amount: money_in_cents.to_f / 100,
                                               account_id: credit_card[:id],
                                               order_id: order.number,
                                               onvoice_number: order.number
                                           })
        logger.info "#{payment}"
        Response.new(true, nil, payment)
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        Response.new(false, e.message)
      end

    end

    def authorize(money_in_cents, source, gateway_options)
      purchase money_in_cents, source, gateway_options
    end

    def credit(credit_cents, transaction_id, _options)
      begin
        payment = provider::Payment.get(transaction_id)
        logger.info payment

        if payment[:status] == 'Voided'
          Response.new(true , "Payment already voided")
        elsif payment[:status] == 'Authorized'
          void(response_code,nil)
        else
          response = provider::Payment.refund(transaction_id)
          logger.info response
          success = response[:status] == 'Reversed' ? true : false
          Response.new(success, nil, response)
        end
      rescue =>e
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
      rescue =>e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        Response.new(false, e.message)
      end

    end

    def cancel(response_code)
      void(response_code,nil)
    end


  end
end