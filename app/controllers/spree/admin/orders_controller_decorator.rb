module Spree
  module Admin
    module OrdersControllerDecorator
      def cancel
        begin
          @order.canceled_by(try_spree_current_user)
          flash[:success] = Spree.t(:order_canceled)
        rescue => e
          logger.error e.message
          logger.error e.backtrace.join("\n")
          flash[:error] = e.message
        end
        redirect_back fallback_location: spree.edit_admin_order_url(@order)
      end
    end
  end
end

::Spree::Admin::OrdersController.prepend Spree::Admin::OrdersControllerDecorator
