//= require spree/frontend

Spree.routes.paysimple_auth = Spree.pathFor('paysimple/auth');
var CHECKOUT_BTN = $("#checkout_form_payment [data-hook=buttons] .checkout-content-save-continue-button");
var paysimplejs = null;
SpreePaySimple = {
    loadPaysimpleJs: function (auth) {
        paysimplejs = window.paysimpleJs({
            container: document.querySelector('#psjs'),
            auth: auth,
            bypassPostalCodeValidation: false,
            preventAutocomplete: false,
            styles: {
                body: {
                    backgroundColor: '#fff'
                }
            }
        });

        paysimplejs.on('accountRetrieved', this.onAccountRetrieved);
        paysimplejs.on('formValidityChanged', function (body) {
        });

        paysimplejs.on('httpError', function (error) {
            alert('Error, please try again later.')
        });
        // Load the credit card key enter form
        paysimplejs.send.setMode('cc-key-enter');
        // Add an event listener to your submit button
        var $this = this
        CHECKOUT_BTN.on('click', function (event) {
            event.preventDefault();
            $this.onSubmit(event)

            return false
        });
    },

    // Called when the PaySimpleJS SDK retrieves the account info
    onAccountRetrieved: function (accountInfo) {
        console.log(accountInfo)

        $('<input>').attr({
            type: 'hidden',
            value: accountInfo['paymentToken'],
            name: 'payment_source[' + SpreePaySimple.paymentMethodID + '][payment_token]'
        }).appendTo('#checkout_form_payment');
        $('<input>').attr({
            type: 'hidden',
            value: accountInfo['account']['id'],
            name: 'payment_source[' + SpreePaySimple.paymentMethodID + '][account_id]'
        }).appendTo('#checkout_form_payment');
        $('<input>').attr({
            type: 'hidden',
            value: SpreePaySimple.customer.firstName + ' ' + SpreePaySimple.customer.firstName,
            name: 'payment_source[' + SpreePaySimple.paymentMethodID + '][name]'
        }).appendTo('#checkout_form_payment');
        $('#checkout_form_payment').submit()
    },

    // Submit button event listener -- triggered when the user clicks the submit button.
    // Sumbit the merchant form data to the PaySimpleJS SDK
    onSubmit: function () {
        var customer = {
            firstName: SpreePaySimple.customer.firstName,
            lastName: SpreePaySimple.customer.lastName,
            email: SpreePaySimple.customer.email
        };
        paysimplejs.send.retrieveAccount(customer);
    },


    // Obtain a Checkout Token from your server
    getAuth: function () {
        CHECKOUT_BTN.attr('disabled', true)
        var $this = this
        return $.ajax({
            url: Spree.routes.paysimple_auth + '?payment_method_id=' + SpreePaySimple.paymentMethodID
        }).done(function (data, statusText, xhr) {
            if (xhr.status < 300) {
                console.log(data)
                $this.loadPaysimpleJs({
                    token: data.jwt_token
                });
                CHECKOUT_BTN.attr('disabled', false)
                return;
            }

            alert('Error, please try again later');
        })
    },
}

