module Spree
  class PaysimpleController < StoreController
    def auth
      begin
        response = payment_method.provider.request('post', '/checkouttoken', params = {json: true})
      rescue => e
        logger.info(payment_method.provider.api_url('/checkouttoken'))
        logger.info("#{payment_method.provider.api_user} #{payment_method.provider.api_key}")
        logger.error "#{e}"
        logger.error e.backtrace.join("\n")
      end
      render json: response
    end

    private

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def provider
      payment_method.provider
    end
  end
end
