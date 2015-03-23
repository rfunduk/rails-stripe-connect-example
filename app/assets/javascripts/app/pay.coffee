$(document).ready ->
  return unless StripeCheckout?

  # Keeps track of whether we're in the middle of processing
  # a payment or not. This way we can tell if the 'closed'
  # event was due to a successful token generation, or the user
  # closing it by hand.
  submitting = false

  payButton = $('.pay-button')
  form = payButton.closest('form')
  destination = form.find('select[name=charge_on]')
  indicator = form.find('.indicator').height( form.outerHeight() )
  handler = null

  createHandler = ->
    handler = StripeCheckout.configure
      # Grab the correct publishable key. Depending on
      # the selection in the interface.
      key: window.publishable[destination.val()]

      # The email of the logged in user.
      email: window.currentUserEmail

      allowRememberMe: false
      closed: ->
        form.removeClass('processing') unless submitting
      token: ( token ) ->
        submitting = true
        form.find('input[name=token]').val( token.id )
        form.get(0).submit()

  destination.change createHandler
  createHandler()

  payButton.click ( e ) ->
    e.preventDefault()
    form.addClass( 'processing' )

    handler.open
      name: 'Rails Connect Example'
      description: '$10 w/ 10% fees'
      amount: 1000
