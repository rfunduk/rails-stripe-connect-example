class UsersController < ApplicationController
  # Most actions here need a logged in user.
  # ApplicationHelper#current_user will return the logged in user.
  before_action :require_user, except: %w{ new create }

  # A list of all users in the database.
  # app/views/users/index.html.haml
  def index
    @users = User.all
  end

  # A signup form.
  # app/views/users/new.html.haml
  def new
    @user = User.new
  end

  # Create a new user via #new
  # Log them in after creation, and take
  # them to their own 'profile page'.
  def create
    @user = User.create( user_params )
    session[:user_id] = @user.id
    if @user.valid?
      redirect_to user_path( @user )
    else
      render action: 'new'
    end
  end

  # Show a user's profile page.
  # This is where you can spend money with the connected account.
  # app/views/users/show.html.haml
  def show
    @user = User.find( params[:id] )
    @plans = Stripe::Plan.all
  end

  # Connect yourself to a Stripe account.
  # Only works on the currently logged in user.
  # See app/services/stripe_connect.rb for #connect_url details.
  def connect
    connector = StripeConnect.new( current_user )
    connect_url, error = connector.connect_url( redirect_uri: confirm_users_url )

    if connect_url.nil?
      flash[:error] = error
      redirect_to user_path( current_user )
    else
      redirect_to connect_url
    end
  end

  # Confirm a connection to a Stripe account.
  # Only works on the currently logged in user.
  # See app/services/stripe_connect.rb for #verify! details.
  def confirm
    connector = StripeConnect.new( current_user )
    if params[:code]
      # If we got a 'code' parameter. Then the
      # connection was completed by the user.
      connector.verify!( params[:code] )

    elsif params[:error]
      # If we have an 'error' parameter, it's because the
      # user denied the connection request. Other errors
      # are handled at #connect_url generation time.
      flash[:error] = "Authorization request denied."
    end

    redirect_to user_path( current_user )
  end

  # Deauthorize the application from accessing
  # the connected Stripe account.
  # Only works on the currently logged in user.
  def deauthorize
    connector = StripeConnect.new( current_user )
    connector.deauthorize!
    flash[:notice] = "Account disconnected from Stripe."
    redirect_to user_path( current_user )
  end

  # Make a one-off payment to the user.
  # See app/assets/javascripts/app/pay.coffee
  def pay
    # Find the user to pay.
    user = User.find( params[:id] )

    # Charge $10.
    amount = 1000
    # Calculate the fee amount that goes to the application.
    fee = (amount * Rails.application.secrets.fee_percentage).to_i

    begin
      charge = Stripe::Charge.create(
        {
          amount: amount,
          currency: user.currency,
          card: params[:token],
          description: "Test Charge via Stripe Connect",
          application_fee: fee
        },

        # Use the user-to-be-paid's access token
        # to make the charge.
        user.secret_key
      )
      flash[:notice] = "Charged successfully! <a target='_blank' rel='connected-account' href='https://dashboard.stripe.com/test/payments/#{charge.id}'>View in dashboard &raquo;</a>"

    rescue Stripe::CardError => e
      error = e.json_body[:error][:message]
      flash[:error] = "Charge failed! #{error}"
    end

    redirect_to user_path( user )
  end

  # Subscribe the currently logged in user to
  # a plan owned by the application.
  # See app/assets/javascripts/app/subscribe.coffee
  def subscribe
    # Find the user to pay.
    user = User.find( params[:id] )

    # Calculate the fee percentage that applies to
    # all invoices for this subscription.
    fee_percent = (Rails.application.secrets.fee_percentage * 100).to_i
    begin
      # Create a customer and subscribe them to a plan
      # in one shot.
      # Normally after this you would store customer.id
      # in your database so that you can keep track of
      # the subscription status/etc. Here we're just
      # fire-and-forgetting it.
      customer = Stripe::Customer.create(
        {
          card: params[:token],
          email: current_user.email,
          plan: params[:plan],
          application_fee_percent: fee_percent
        },
        user.secret_key
      )
      flash[:notice] = "Subscribed! <a target='_blank' rel='app-owner' href='https://dashboard.stripe.com/test/customers/#{customer.id}'>View in dashboard &raquo;</a>"

    rescue Stripe::CardError => e
      error = e.json_body[:error][:message]
      flash[:error] = "Charge failed! #{error}"
    end

    redirect_to user_path( user )
  end

  private

  def user_params
    p = params.require(:new_user).permit( :name, :email, :password )
    p[:email].downcase!
    p
  end

end
