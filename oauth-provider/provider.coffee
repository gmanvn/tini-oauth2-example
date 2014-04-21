_ = require 'lodash'
mongoose = require 'mongoose'
oauth2orize = require 'oauth2orize'
fibrous = require 'fibrous'
ensureLogin = require 'connect-ensure-login'
passport = require('passport')

require './model-grant.coffee'
require './model-access-token.coffee'



class Provider

  @uid = uid = ()->
    uid.counter = uid.counter or 0
    counter = ++uid.counter
    random = String(Math.random()) + Date.now() + counter
    random = Number random[2..]
    random.toString 36

  defaultRenderFunction = (req, res)->
    res.render('dialog', { transactionID: req.oauth2.transactionID, user: req.user, client: req.oauth2.client })



  constructor: (config)->
    ## normalize parameters
    throw new Error 'Your argument is invalid: need config object' unless config?
    @userModelName = config.naming?.model or 'user'
    @clientModelName = config.naming?.model or 'client'
    @grantsModelName = 'grant'
    @accessTokenModelName = 'accessToken'

    @renderFunction = config.renderFunction or defaultRenderFunction

    ## init models
    @db =
      user: mongoose.model @userModelName
      client: mongoose.model @clientModelName
      grant: mongoose.model @grantsModelName
      accessToken: mongoose.model @accessTokenModelName


    ## init oauth server
    @server = oauth2orize.createServer()

    ## register serialize/deserialize functions (easier for inheritance)
    @server.serializeClient ()=>
      @serialize arguments...

    @server.deserializeClient ()=>
      @deserialize arguments...

    ## register grant code
    @server.grant oauth2orize.grant.code (client, redirectURI, user, ares, done)=>
      code = uid()
      grant = new @db.grant {
        code
        redirectURI
        client: client.id
        user: user.id
      }

      grant.save (err)->
        return done err if err
        done null, code

    ## grant implicit token
    @server.grant oauth2orize.grant.token (client, user, ares, done)=>
      code = uid()
      accessToken = new @db.accessToken {
        token: code
        client: client.clientId
        user: user.id
      }

      accessToken.save (err)->
        return done err if err
        done null, code

    ## exchange grant for access token
    @server.exchange oauth2orize.exchange.code (client, code, redirectURI, done)=>
      @db.grant.findOne {code}, (err, grant)=>
        return done err if err
        return done err, false if client.id isnt grant.client or redirectURI isnt grant.redirectURI

        token = uid()
        accessToken = new @db.accessToken {
          token
          user: grant.user
          client: grant.client
        }

        accessToken.save (err)->
          return done err if err
          done null, token

    ## exchange id/password for access token
    @server.exchange oauth2orize.exchange.password (client, username, password, scope, done)=>
      fibrous.run =>
        ## validating client
        clientId = client.clientId
        clientSecret = client.clientSecret
        localClient = @db.client.sync.find clientId

        return false unless localClient?.clientSecret is clientSecret

        ## validating user
        user = @db.user.sync.find username
        return false unless user?.password is password

        ## response a access token
        token = uid()
        accessToken = new @db.accessToken {
          token
          user: user.id
          client: clientId
        }

        accessToken.save()
        return token
      , done

  ## serialize client into session storage (can be overwrite)
  serialize: (client, done)-> done null, client.id

  ## deserialize client from session storage (can be overwrite)
  deserialize: (id, done)->
    ## get client (consumer)
    @db.client.findById id, (err, client)->
      return done err if err
      done null, client


  authorization: ->
    [
      ensureLogin.ensureLoggedIn()

      @server.authorization (clientId, redirectURI, done)=>
        @db.client.findOne {clientId}, (err, client)->
          return done err if err
          ## WARNING: For security purposes, it is highly advisable to check that
          ##          redirectURI provided by the client matches one registered with
          ##          the server.  For simplicity, this example does not.  You have
          ##          been warned.
          done null, client, redirectURI

      @renderFunction
    ]

  decision: ->
    [
      ensureLogin.ensureLoggedIn()
      @server.decision()
    ]

  token: ->
    [
      passport.authenticate(['basic', 'oauth2-client-password'], { session: false }),
      @server.token(),
      @server.errorHandler()
    ]

module.exports = Provider