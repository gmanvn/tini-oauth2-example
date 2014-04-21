###
Module dependencies.
###
passport = require("passport")
LocalStrategy = require("passport-local").Strategy
BasicStrategy = require("passport-http").BasicStrategy
ClientPasswordStrategy = require("passport-oauth2-client-password").Strategy
BearerStrategy = require("passport-http-bearer").Strategy
mongoose = require 'mongoose'

###
LocalStrategy

This strategy is used to authenticate users based on a username and password.
Anytime a request is made to authorize an application, we must ensure that
a user is logged in before asking them to approve the request.
###
passport.use new LocalStrategy((username, password, done) ->
  mongoose.model('user').findOne {username}, (err, user) ->
    return done(err)  if err
    return done(null, false)  unless user
    return done(null, false)  unless user.password is password
    done null, user

  return
)
passport.serializeUser (user, done) ->
  done null, user.id
  return

passport.deserializeUser (id, done) ->
  mongoose.model('user').findById id, (err, user) ->
    done err, user
    return

  return


###
BasicStrategy & ClientPasswordStrategy

These strategies are used to authenticate registered OAuth clients.  They are
employed to protect the `token` endpoint, which consumers use to obtain
access tokens.  The OAuth 2.0 specification suggests that clients use the
HTTP Basic scheme to authenticate.  Use of the client password strategy
allows clients to send the same credentials in the request body (as opposed
to the `Authorization` header).  While this approach is not recommended by
the specification, in practice it is quite common.
###
passport.use new BasicStrategy((username, password, done) ->
  mongoose.model('client').findOne {username}, (err, client) ->
    return done(err)  if err
    return done(null, false)  unless client
    return done(null, false)  unless client.clientSecret is password
    done null, client

  return
)
passport.use new ClientPasswordStrategy((clientId, clientSecret, done) ->
  mongoose.model('client').findOne {clientId}, (err, client) ->
    return done(err)  if err
    return done(null, false)  unless client
    return done(null, false)  unless client.clientSecret is clientSecret
    done null, client

  return
)

###
BearerStrategy

This strategy is used to authenticate either users or clients based on an access token
(aka a bearer token).  If a user, they must have previously authorized a client
application, which is issued an access token to make requests on behalf of
the authorizing user.
###
passport.use new BearerStrategy((accessToken, done) ->
  mongoose.model('accessToken').findOne {token: accessToken}, (err, token) ->
    return done(err)  if err
    return done(null, false)  unless token
    if token.user?
      mongoose.model('user').findById token.user, (err, user) ->
        return done(err)  if err
        return done(null, false)  unless user

        # to keep this example simple, restricted scopes are not implemented,
        # and this is just for illustrative purposes
        info = scope: "*"
        done null, user, info
        return

    else

      #The request came from a client only since user is null
      #therefore the client is passed back instead of a user
      mongoose.model('client').findById token.clientID, (err, client) ->
        return done(err)  if err
        return done(null, false)  unless client

        # to keep this example simple, restricted scopes are not implemented,
        # and this is just for illustrative purposes
        info = scope: "*"
        done null, client, info
        return

    return

  return
)