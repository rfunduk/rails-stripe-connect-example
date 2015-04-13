class StripeManaged < Struct.new( :user )
  ALLOWED = [ 'US', 'CA' ] # public beta
  COUNTRIES = [
    { name: 'United States', code: 'US' },
    { name: 'Canada', code: 'CA' },
    { name: 'Australia', code: 'AU' },
    { name: 'United Kingdom', code: 'UK' },
    { name: 'Ireland', code: 'IE' }
  ]

  def create_account!( country, tos_accepted, ip )
    return nil unless tos_accepted
    return nil unless country.in?( COUNTRIES.map { |c| c[:code] } )

    begin
      @account = Stripe::Account.create(
        managed: true,
        country: country,
        email: user.email,
        # decline_charge_on: {
        #   cvc_failure: true,
        #   avs_failure: true
        # },
        tos_acceptance: {
          ip: ip,
          date: Time.now.to_i
        },
        legal_entity: {
          type: 'individual',
        }
      )
    rescue
      nil # TODO: improve
    end

    if @account
      user.update_attributes(
        currency: @account.default_currency,
        stripe_account_type: 'managed',
        stripe_user_id: @account.id,
        secret_key: @account.keys.secret,
        publishable_key: @account.keys.publishable,
        stripe_account_status: managed_status
      )
    end

    @account
  end

  def update_account!( params: nil )
    if params
      if params[:bank_account_token]
        account.bank_account = params[:bank_account_token]
        account.save
      end

      if params[:legal_entity]
        # clean up dob fields
        params[:legal_entity][:dob] = {
          year: params[:legal_entity].delete('dob(1i)'),
          month: params[:legal_entity].delete('dob(2i)'),
          day: params[:legal_entity].delete('dob(3i)')
        }

        # build a new legal_entity hash from the params
        new_legal_entity = {}
        params[:legal_entity].entries.each do |key, value|
          if [ :address, :dob ].include? key.to_sym
            value.entries.each do |akey, avalue|
              next if avalue.blank?
              # Rails.logger.error "#{akey} - #{avalue.inspect}"
              new_legal_entity[key] ||= {}
              new_legal_entity[key][akey] = avalue
            end
          else
            next if value.blank?
            # Rails.logger.error "#{key} - #{value.inspect}"
            new_legal_entity[key] = value
          end
        end

        account.legal_entity = new_legal_entity
        account.save
      end
    end

    user.update_attributes(
      stripe_account_status: account_status
    )
  end

  def legal_entity
    account.legal_entity
  end

  def needs?( field )
    user.stripe_account_status['fields_needed'].grep( Regexp.new( /#{field}/i ) ).any?
  end

  def supported_bank_account_countries
    country_codes = case account.country
                    when 'US' then %w{ US }
                    when 'CA' then %w{ US CA }
                    when 'IE', 'UK' then %w{ IE UK US }
                    when 'AU' then %w{ AU }
                    end
    COUNTRIES.select do |country|
      country[:code].in? country_codes
    end
  end

  protected

  def account_status
    {
      details_submitted: account.details_submitted,
      charges_enabled: account.charges_enabled,
      transfers_enabled: account.transfers_enabled,
      fields_needed: account.verification.fields_needed,
      due_by: account.verification.due_by
    }
  end

  def account
    @account ||= Stripe::Account.retrieve( user.stripe_user_id )
  end

end
