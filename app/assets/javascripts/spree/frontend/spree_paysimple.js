//= require spree/frontend

Spree.routes.paysimple_auth = Spree.pathFor('paysimple/auth');
var CHECKOUT_BTN = $("#checkout_form_payment [data-hook=buttons] .checkout-content-save-continue-button");
var paysimplejs = null;
SpreePaySimple = {
    loadPaysimpleJs: function (auth) {
        paysimplejs = window.paysimpleJs({
            // Element that will contain the iframe
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

        // Configure a callback to complete the checkout after the
        // PaySimpleJS SDK retrieves the account
        paysimplejs.on('accountRetrieved', this.onAccountRetrieved);
        // Listen to the 'formValidityChanged' event to enable your submit button
        // where body = { validity: <'true' | 'false'> }
        paysimplejs.on('formValidityChanged', function (body) {
            // if (body === 'true') {
            //     CHECKOUT_BTN.attr('disabled', true)
            // } else {
            //     CHECKOUT_BTN.attr('disabled', false)
            // }
        });
        // Listen to the 'httpError' event
        // where error = {
        // errorKey: <'timeout' | 'bad_request' | 'server_error'
        // | 'unauthorized' | 'unknown'>,
        // errors: <array of { field: <string>, message: <string> }>,
        // status: <number - http status code returned>
        // }

        paysimplejs.on('httpError', function (error) {
            alert('Error, please try again later.')
        });
        // Load the credit card key enter form
        paysimplejs.send.setMode('cc-key-enter');
        // Add an event listener to your submit button
        $('#checkout_form_payment').on('submit', this.onSubmit);
    },

    // Called when the PaySimpleJS SDK retrieves the account info
    onAccountRetrieved: function (accountInfo) {
        console.log(accountInfo)
        // Send the accountInfo to your server to collect a payment
        // for an existing customer

        $('#checkout_form_payment').submit()
        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/payment');
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.onload = function (e) {
            if (xhr.status < 300) {
                var data = JSON.parse(this.response);
                console.log('Successfully created Payment:\nTrace #: ' + data.TraceNumber);
            } else {
                console.log('Failed to create Payment: (' + xhr.status + ') ' + xhr.responseText);
            }
        }
        xhr.send(JSON.stringify(accountInfo));
    },

    // Submit button event listener -- triggered when the user clicks the submit button.
    // Sumbits the merchant form data to the PaySimpleJS SDK
    onSubmit: function (event) {
        event.preventDefault();
        var customer = {
            firstName: SpreePaySimple.customer.firstName,
            lastName: SpreePaySimple.customer.lastName,
            email: SpreePaySimple.customer.email
        };
        paysimplejs.send.retrieveAccount(customer);
    },


    // Obtain a Checkout Token from your server
    getAuth: function () {
        var $this = this
        return $.ajax({
            url: Spree.routes.paysimple_auth + '?payment_method_id=' + SpreePaySimple.paymentMethodID
        }).done(function (data, statusText, xhr) {
            if (xhr.status < 300) {
                console.log(data)
                $this.loadPaysimpleJs({
                    token: data.jwt_token
                });
                return;
            }

            alert('Error, please try again later');
        })
    },
}

document.addEventListener('turbolinks:load', function () {
    SpreePaySimple.getAuth();
})