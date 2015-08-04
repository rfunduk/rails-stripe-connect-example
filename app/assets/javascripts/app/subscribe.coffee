$(document).ready ->
  return unless StripeCheckout?

  # Holds the plan selected by the user in the interface.
  currentPlan = null

  # Keeps track of whether we're in the middle of processing
  # a payment or not. This way we can tell if the 'closed'
  # event was due to a successful token generation, or the user
  # closing it by hand.
  submitting = false

  subscribeButton = $('.subscribe-button')
  planButtons = $('.plan-choice')
  form = subscribeButton.closest('form')
  destination = form.find('select[name=charge_on]')
  indicator = form.find('.indicator').height( form.outerHeight() )

  handler = StripeCheckout.configure
    # The publishable key of the **connected account**.
    key: window.publishable[destination.val()]

    # The email of the logged in user.
    email: window.currentUserEmail

    allowRememberMe: false
    closed: ->
      subscribeButton.attr( disabled: true )
      planButtons.removeClass('active')
      currentPlan = null
      form.removeClass('processing') unless submitting
    token: ( token ) ->
      submitting = true
      form.find('input[name=token]').val( token.id )
      form.get(0).submit()

  planButtons.click ( e ) ->
    e.preventDefault()

    planButton = $(this)
    planButton.addClass('active').siblings().removeClass('active')
    subscribeButton.attr( disabled: false )

    # Get current plan info from the clicked element's data attributes
    currentPlan =
      id: planButton.data('id')
      name: planButton.data('name')
      currency: planButton.data('currency')
      amount: parseInt planButton.data('amount'), 10

    form.find('input[name=plan]').val( currentPlan.id )

    subscribeButton.show()

  subscribeButton.click ( e ) ->
    e.preventDefault()
    form.addClass('processing')

    if currentPlan == null
      alert "Choose a plan first!"
      return

    handler.open
      name: 'Rails Connect Example'
      description: "#{currentPlan.name} Subscription"
      amount: currentPlan.amount
