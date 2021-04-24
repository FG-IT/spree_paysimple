module Spree
  class PaySimpleCheckout < ActiveRecord::Base


    def self.create_from_token(token)
      create!(payment_token: token)
    end


    def actions
      %w(void settle credit)
    end

    def can_void?(_payment)
      if _payment.pending? || _payment.checkout?
        true
      else
        %w(authorized pending).include? state
      end
    end

    def can_settle?(_)
      %w(authorized).include? state
    end

    def can_credit?(_payment)
      %w(settled settling complete).include? state
    end

  end
end
