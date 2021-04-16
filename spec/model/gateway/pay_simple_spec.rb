describe Spree::Gateway::PaySimple do
  let(:gateway) { Spree::Gateway::PaySimple.create!({
                                                        name: 'PaySimple',
                                                        preferred_login: 'APIUser156326',
                                                        preferred_password: 'tBOIg1ChLiJGNk8hiQ0Fgpbcs7NE3aHAC7YZaimt2PtNw3hDpGcw8vNwD4bcMIwLr6Wf5Zs7VLFEixuXZ2O7YDQLEXlceCdUMUo2PleWh5BeQjx8xrEu3jOWCwIXTG50'
                                                    }) }
  let(:customer_data) {
    {first_name: 'xq', last_name: 'x', email: 'johnnyxiang2017@gmail.com'}
  }

  let (:utils) {
    Spree::Gateway::PaySimple::Utils.new(gateway, nil)
  }

  it "credit card issuer" do
    issuer = utils.detect_issuer('5555555555554444')
    expect(issuer).to eq Paysimple::Issuer::MASTER_CARD
  end

    context "payment purchase" do
      it "customer" do
        customer = utils.fetch_customer_id(customer_data)
        expect(customer).to eq 1288391
      end

      it "payment 9999.01" do
        account_id = 1310339

        payment = gateway.provider::Payment.create({
                                                       amount: 9999.01,
                                                       account_id: account_id
                                                   })

        puts Spree::Gateway::PaySimple::Response.new(true, nil, payment)

        payment = gateway.provider::Payment.create({
                                                       amount: 9999.02,
                                                       account_id: account_id
                                                   })

        puts Spree::Gateway::PaySimple::Response.new(true, nil, payment)
        payment = gateway.provider::Payment.create({
                                                       amount: 9999.03,
                                                       account_id: account_id
                                                   })
        puts Spree::Gateway::PaySimple::Response.new(true, nil, payment)
        payment = gateway.provider::Payment.create({
                                                       amount: 9999.04,
                                                       account_id: account_id
                                                   })
        puts Spree::Gateway::PaySimple::Response.new(true, nil, payment)
        payment = gateway.provider::Payment.create({
                                                       amount: 9999.05,
                                                       account_id: account_id
                                                   })
        puts Spree::Gateway::PaySimple::Response.new(true, nil, payment)
      end
    end


end
