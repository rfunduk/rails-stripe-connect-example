class HooksController < ApplicationController
  # Webhooks can't possibly know our CSRF token.
  # So disable that feature entirely for this controller.
  skip_before_action :verify_authenticity_token

  def stripe
    # If the request has a 'user_id' key, then this is a webhook
    # event sent regarding a connected user, and not to a webhook
    # handler setup on the application owner's account.
    # So, use the user_id to look up a connected user on our end.
    user = params[:user_id] && User.find_by( stripe_user_id: params[:user_id] )

    # If we didn't find a user, we'll have nil instead
    # so build our arguments to the Event API taking that into account.
    # We'll end up with one of:
    #   args = [ 'EVENT_ID' ]
    #   args = [ 'EVENT_ID', 'ACCESS_TOKEN' ]
    args = [ params[:id], user.try(:secret_key) ].compact

    # Retrieve the event from Stripe so that we can be
    # sure it wasn't spoofed/faked by someone being mean.
    begin
      event = Stripe::Event.retrieve( *args )
    rescue Stripe::InvalidRequestError
      # The event doesn't exist for some reason... this might
      # happen if you've got other apps maybe?
      render nothing: true, status: 200
      return
    rescue Stripe::AuthenticationError
      # If we get an authentication error, and the event belongs to
      # a user, that means the account deauthorized
      # our application. We can't look up and verify the event
      # because the event belongs to the connected account, and we're
      # no longer authorized to access their account!
      if user && user.connected?
        connector = StripeConnect.new( user )
        connector.deauthorized
      end

      render nothing: true, status: 200
      return
    end

    # Here we're actually done, but if you wanted to handle
    # other events (charges or invoice payment failures, etc)
    # then this is how you would do it.
    case event.try(:type)

    when 'account.application.deauthorized'
      # This is what the account.application.deauthorized
      # handler will hopefully look like some day, where
      # the event is still accessible somehow and we verified
      # it came from Stripe.
      if user && user.connected?
        user.manager.deauthorized
      end

    when 'account.updated'
      # This webhook is used for standalone and managed
      # accounts. It will notify you about new information
      # required for the account to remain in good standing.
      if user && user.connected?
        # we don't actually need to pass the event here
        # we'll request the account details directly inside
        # the manager
        user.manager.update_account!
      end

    # These others simply log the event because there's
    # not much to do with them for this example app.
    # You might do more useful things like sending receipt emails, etc.
    # Of course you can handle as many event types as you need:
    #   https://stripe.com/docs/api#event_types
    when 'charge.succeeded'
      Rails.logger.info "**** STRIPE EVENT **** #{event.type} **** #{event.id}"
    when 'invoice.payment_succeeded'
      Rails.logger.info "**** STRIPE EVENT **** #{event.type} **** #{event.id}"
    when 'invoice.payment_failed'
      Rails.logger.info "**** STRIPE EVENT **** #{event.type} **** #{event.id}"

    end

    # We just need to respond in the affirmative.
    # No body is necessary.
    render nothing: true, status: 200
  end

end
