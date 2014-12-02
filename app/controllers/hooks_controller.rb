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
    # so build our arguments to the Event API taking that into account
    args = [ params[:id], user.try(:secret_key) ].compact

    # We now have one of:
    #   args = [ 'EVENT_ID' ]
    #   args = [ 'EVENT_ID', 'ACCESS_TOKEN' ]
    event = Stripe::Event.retrieve( *args ) rescue nil

    # A list of events we want to handle, can save us
    # some work.
    kinds = %w{ account.application.deauthorized }

    # This is a special case due to 'account.application.deauthorized'
    # events not being accessible anymore (the user deauthorized us, afterall).
    if event.nil? && params[:type] == 'account.application.deauthorized'
      StripeConnect.new( user ).deauthorized

    elsif event.type.in?( kinds )
      case event.type

      # This is what the account.application.deauthorized
      # handler will hopefully look like some day, where
      # the event is still accessible somehow and we verified
      # it came from Stripe.
      when 'account.application.deauthorized'
        # find the user who just deauthorized the app
        user = User.find_by( stripe_user_id: event.user_id )
        if user && user.connected?
          connector = StripeConnect.new( user )
          connector.deauthorized
        end

      end
    end

    # We just need to respond in the affirmative.
    # No body is necessary.
    render nothing: true, status: 200
  end

end
