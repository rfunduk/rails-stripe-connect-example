require 'highline/import'
require 'stripe'
require 'rest-client'
require 'securerandom'

namespace :app do
  desc "Setup this Rails+Stripe Connect Test Application"
  task :setup do
    # If you like you can specify these 3 values via
    # environment variables instead of being prompted for them.
    client_id = ENV['STRIPE_CLIENT_ID']
    publishable_key = ENV['STRIPE_PUBLISHABLE_KEY']
    secret_key = ENV['STRIPE_SECRET_KEY']

    say <<-EOF

                Thanks for trying out the
           <%= color("Rails Stripe Connect Test Application", BOLD) %>!
----------------------------------------------------------------
This script asks for API keys and pre-configures a bunch of
things so that you don't have to tediously create/fill in
settings in a bunch of files.

<%= color("You should read the source of this task in lib/tasks/setup.rake!", :red, BOLD) %>
----------------------------------------------------------------
    EOF

    confirm = %{Have you read the code about to be run and are confident it\ndoesn't do anything scary? (Y/N) }
    confirmed = ask confirm do |q|
      q.case = :up
      q.in = %w{ Y N }
    end

    if confirmed == 'N'
      puts "No worries, come back later :)"
      exit 1
    else
      puts
    end

    client_id ||= ask "What is your application's development client ID? " do |q|
      q.validate = /ca_[a-zA-Z0-9]{32,252}/
      q.echo = "*"
    end

    # with the client id, test that it's correct
    print "Checking client... "
    client_id_test_url = "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=#{client_id}"
    response = RestClient.get client_id_test_url
    if response.code != 200
      puts "That doesn't appear to be a valid client_id. Please see the README"
      exit 1
    else
      puts "OK"
    end

    # now get publishable key
    publishable_key ||= ask "\nWhat is your test publishable key? " do |q|
      q.validate = /pk_test_[a-zA-Z0-9]{24,247}/
      q.echo = "*"
    end

    # check publishable
    print "Checking publishable... "
    token = Stripe::Token.create( {
      card: { number: '4242424242424242',
              exp_month: 1, exp_year: Date.today.year + 3,
              cvc: '123' }
    }, publishable_key ) rescue nil

    if token.nil?
      puts "That publishable key did not appear to work. Please see the README"
      exit 1
    else
      puts "OK\n"
    end


    # now get publishable key
    secret_key ||= ask "\nWhat is your test secret key? " do |q|
      q.validate = /sk_test_[a-zA-Z0-9]{24,247}/
      q.echo = "*"
    end

    # check secret
    print "Checking secret... "
    account = Stripe::Account.retrieve( secret_key ) rescue nil

    if account.nil?
      puts "That secret key did not appear to work. Please see the README"
      exit 1
    else
      puts "OK\n"
    end

    puts "\nGenerating Rails session secret key base..."
    rails_secret_key_base = SecureRandom.hex(64)

    puts "\nGenerating config/secrets.yml..."

    sample_path = File.join( Dir.pwd, 'config/secrets.sample.yml' )
    sample_contents = File.read( sample_path )
    sample_contents.gsub! '__RAILS_SECRET', rails_secret_key_base
    sample_contents.gsub! '__STRIPE_CLIENT', client_id
    sample_contents.gsub! '__STRIPE_PUBLISHABLE', publishable_key
    sample_contents.gsub! '__STRIPE_SECRET', secret_key

    dest_path = File.join( Dir.pwd, 'config/secrets.yml' )
    if File.exists?( dest_path )
      yn = ask "Already exists... should I overwrite it? (Y/N) " do |q|
        q.case = :up
        q.in = %w{ Y N }
      end
      exit 0 if yn == 'N'
    end

    File.write dest_path, sample_contents
    puts "\nDONE"
  end
end
