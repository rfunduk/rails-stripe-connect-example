require 'highline/import'
require 'stripe'
require 'rest-client'
require 'securerandom'

namespace :app do
  desc "Setup this Rails+Stripe Connect Test Application"
  task :setup do
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

    existing_config = Rails.root.join('config/secrets.yml')
    if File.exists?( existing_config )
      # if you have an existing config/secrets.yml
      # we can test it for you
      load_config = ask "You have an existing config/secrets.yml, shall I test it? (Y/N) " do |q|
        q.case = :up
        q.in = %w{ Y N }
      end

      if load_config == 'Y'
        config = YAML.load_file( existing_config )['development']
        client_id = config['stripe_client_id']
        publishable_key = config['stripe_publishable_key']
        secret_key = config['stripe_secret_key']
        puts "Loaded config/secrets.yml\n\n"
      else
        puts
      end
    else
      # or if you like you can specify these 3 values via
      # environment variables instead of being prompted for them.
      use_env = ask "Do you want to try to load configuration from the environment? (Y/N) " do |q|
        q.case = :up
        q.in = %w{ Y N }
      end

      if use_env == 'Y'
        client_id = ENV['STRIPE_CLIENT_ID']
        publishable_key = ENV['STRIPE_PUBLISHABLE_KEY']
        secret_key = ENV['STRIPE_SECRET_KEY']
        loaded = [ ('client_id' if client_id),
                   ('publishable_key' if publishable_key),
                   ('secret_key' if secret_key) ].compact
        puts "Loaded: #{'None' if loaded.empty?}#{loaded.join(', ')}\n\n"
      else
        puts
      end
    end

    client_id ||= ask "What is your application's development client ID? " do |q|
      q.validate = /ca_[a-zA-Z0-9]{14,252}/
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


    # now get secret key
    secret_key ||= ask "\nWhat is your test secret key? " do |q|
      q.validate = /sk_test_[a-zA-Z0-9]{24,247}/
      q.echo = "*"
    end

    # check secret
    print "Checking secret... "
    account = Stripe::Account.retrieve( 'self', secret_key ) rescue nil

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
