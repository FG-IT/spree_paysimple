module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.after_action :update_source_data, only: :update
      ::Spree::PermittedAttributes.source_attributes  << :account_id
      ::Spree::PermittedAttributes.source_attributes  << :payment_token
    end

    private

    def update_source_data
      return true unless current_order
      payment = current_order.payments.last
      return true unless payment
      source = payment.source
      return true unless source.is_a?(Spree::PaySimpleCheckout)

      # source.update(account_id: params[:account_id])
      # source.update(payment_token: params[:payment_token])
    end
  end
end
::Spree::CheckoutController.prepend(Spree::CheckoutControllerDecorator)
