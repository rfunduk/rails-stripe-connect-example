## February 24, 2015 ##

* Update code to latest API version (`2015-02-18`), specify in
  initializer to use this version, and note the version in README.
* Improve/tweak the setup script.


## December 11, 2014 ##

* Shortest `client_id` is now 17 chars (`ca_**************`)


## December 6, 2014 ##

* Changed the webhook handling code quite a bit to make it
  cleaner and simpler. Specifically the case where the account
  was deauthorized - the handler now handles 401 responses
  from the API rather than just sort of `rescue nil` and assuming.
* Mentioned needing `bundler` in addition to Ruby.


## December 2, 2014 ##

*   Initial release.
