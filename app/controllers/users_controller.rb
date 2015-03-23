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

  def update
    manager = current_user.manager
    manager.update_account! params: params
    redirect_to user_path( current_user )
  end

  # Show a user's profile page.
  # This is where you can spend money with the connected account.
  # app/views/users/show.html.haml
  def show
    @user = User.find( params[:id] )
    @plans = Stripe::Plan.all
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
      charge_attrs = {
        amount: amount,
        currency: user.currency,
        source: params[:token],
        description: "Test Charge via Stripe Connect",
        application_fee: fee
      }

      case params[:charge_on]
      when 'connected'
        # Use the user-to-be-paid's access token
        # to make the charge directly on their account
        charge = Stripe::Charge.create( charge_attrs, user.secret_key )
      when 'platform'
        # Use the platform's access token, and specify the
        # connected account's user id as the destination so that
        # the charge is transferred to their account.
        charge_attrs[:destination] = user.stripe_user_id
        charge = Stripe::Charge.create( charge_attrs )
      end

      flash[:notice] = "Charged successfully! <a target='_blank' rel='#{params[:charge_on]}-account' href='https://dashboard.stripe.com/test/payments/#{charge.id}'>View in dashboard &raquo;</a>"

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
          source: params[:token],
          email: current_user.email,
          plan: params[:plan],
          application_fee_percent: fee_percent
        },
        user.secret_key
      )
      flash[:notice] = "Subscribed! <a target='_blank' rel='platform-account' href='https://dashboard.stripe.com/test/customers/#{customer.id}'>View in dashboard &raquo;</a>"

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
