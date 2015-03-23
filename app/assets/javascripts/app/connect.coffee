$(document).ready ->
  # pre-connection
  setupManaged()
  setupStandalone()

  # connected user, but we need info
  setupFieldsNeeded()

setupManaged = ->
  container = $('#stripe-managed')
  return if container.length == 0
  tosEl = container.find('.tos input')
  countrySelect = container.find('.country')
  form = container.find('form')
  createButton = form.find('.btn')

  tosEl.change -> createButton.toggleClass 'disabled', !tosEl.is(':checked')
  form.submit ( e ) ->
    # prevent creation unless ToS is checked
    if !tosEl.is(':checked')
      e.preventDefault()
      return false

    createButton.addClass('disabled').val('...')

  # populate appropriate ToS link depending on dropdown
  countrySelect.change ->
    termsUrl = "https://stripe.com/#{countrySelect.val().toLowerCase()}/terms"
    tosEl.siblings('a').attr( href: termsUrl )

setupStandalone = ->
  container = $('#stripe-standalone')
  return if container.length == 0
  countrySelect = container.find('.country')
  form = container.find('form')
  createButton = form.find('.btn')

  form.submit ( e ) ->
    createButton.addClass('disabled').val('...')

setupFieldsNeeded = ->
  container = $('.needed')
  return if container.length == 0

  form = container.find('form')

  form.submit ( e ) ->
    button = form.find('.buttons .btn')
    button.addClass('disabled').val('Saving...')

    # bank account tokenization
    if (baContainer = form.find('#bank-account')).length > 0
      Stripe.setPublishableKey baContainer.data('publishable')
      tokenField = form.find('#bank_account_token')
      if tokenField.is(':empty')
        e.preventDefault()
        Stripe.bankAccount.createToken form, ( _, resp ) ->
          if resp.error
            button.removeClass('disabled').val('Save Info')
            alert( resp.error.message )
          else
            tokenField.val( resp.id )
            form.get(0).submit()
        return false
