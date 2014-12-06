## December 6, 2014 ##

* Changed the webhook handling code quite a bit to make it
  cleaner and simpler. Specifically the case where the account
  was deauthorized - the handler now handles 401 responses
  from the API rather than just sort of `rescue nil` and assuming.
* Mentioned needing `bundler` in addition to Ruby.


## December 2, 2014 ##

*   Initial release.
