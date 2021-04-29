module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      ::Spree::PermittedAttributes.source_attributes << :account_id
      ::Spree::PermittedAttributes.source_attributes << :payment_token
    end


  end
end
::Spree::CheckoutController.prepend(Spree::CheckoutControllerDecorator)
