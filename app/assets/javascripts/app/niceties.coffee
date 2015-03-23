$(document).ready ->
  setTimeout(
    -> $('.alert.alert-info.auto').slideUp('fast')
    3500
  )

  $('body').on 'click', 'a[rel=platform-account]', ( e ) ->
    return confirm("This link will only work if you're logged in as the **application owner**. Continue?")
  $('body').on 'click', 'a[rel=connected-account]', ( e ) ->
    return confirm("This link will only work if you're logged in as the **connected account**. Continue?")
