
module Spree
  class Gateway
    class PaySimple
      class Utils
        attr_reader :order, :customer, :gateway

        def initialize(gateway, order)
          @order = order
          begin
            @customer = gateway.provider::Customer.get(order.user.id) if order.user
          rescue
          end
          @gateway = gateway
        end

        def get_address(address_type)
          address_data(address_type, order)
        end

        def get_customer
          customer_data(order.user)
        end

        def fetch_customer_id(customer_data)
          customers = @gateway.provider::Customer.find({email: customer_data['email'], lite: true})
          if customers.size > 0
            customer_id = customers[0][:id]
          else
            customer = @gateway.provider::Customer.create({
                                                              first_name: customer_data['first_name'],
                                                              last_name: customer_data['last_name'],
                                                              email: customer_data['email']
                                                          })
            customer_id = customer[:id]
          end
          customer_id
        end


        def order_data(identifier, amount)
          identifier.merge(
              amount: amount,
              order_id: order.number
          )
        end

        def address_data(address_type, target)
          address = target.send("#{address_type}_address")
          country = address.country

          {
              company: address.company,
              country_code_alpha2: country.iso,
              country_code_alpha3: country.iso3,
              country_code_numeric: country.numcode,
              country_name: country.name,
              first_name: address.first_name,
              last_name: address.last_name,
              locality: address.city,
              postal_code: address.zipcode,
              region: address.state.try(:abbr),
              street_address: address.address1,
              extended_address: address.address2
          }
        end

        def customer_data(user)
          address_data('billing', user).slice(:first_name, :last_name, :company, :phone).merge!(id: user.id, email: user.email)
        end


        def map_payment_status(braintree_status)
          case braintree_status
          when 'authorized', 'settlement_pending'
            'pending'
          when 'voided'
            'void'
          when 'settled', 'submitted_for_settlement', 'settling'
            'completed'
          else
            'failed'
          end
        end


        def detect_issuer(number)
          #Visa, Master,Amex,Discover

          detector = ::ActiveMerchant::Billing::CreditCard.new({number: number})

          case detector.brand
          when 'visa'
            Paysimple::Issuer::VISA
          when 'master'
            Paysimple::Issuer::MASTER_CARD
          when 'american_express'
            Paysimple::Issuer::AMERICAN_EXPRESS
          when 'discover'
            Paysimple::Issuer::DISCOVER
          else
            raise "Credit card number is invalid."
          end

        end

      end
    end
  end
end