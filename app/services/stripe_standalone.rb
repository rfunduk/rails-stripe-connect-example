class StripeStandalone < Struct.new( :user )
  COUNTRIES = [
    { name: 'United States', code: 'US' },
    { name: 'Canada', code: 'CA' },
    { name: 'Australia', code: 'AU' },
    { name: 'United Kingdom', code: 'GB' },
    { name: 'Ireland', code: 'IE' }
  ]

  def create_account!( country )
    return nil unless country.in?( COUNTRIES.map { |c| c[:code] } )

    begin
      @account = Stripe::Account.create(
        email: user.email,
        managed: false,
        country: country
      )
    rescue
      nil # TODO: improve
    end

    if @account
      user.update_attributes(
        currency: @account.default_currency,
        stripe_account_type: 'standalone',
        stripe_user_id: @account.id,
        secret_key: @account.keys.secret,
        publishable_key: @account.keys.publishable,
        stripe_account_status: account_status
      )
    end

    @account
  end

  protected

  def account_status
    {
      details_submitted: account.details_submitted,
      charges_enabled: account.charges_enabled,
      transfers_enabled: account.transfers_enabled
    }
  end

  def account
    @account ||= Stripe::Account.retrieve( user.stripe_user_id )
  end

end
