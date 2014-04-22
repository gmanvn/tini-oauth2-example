Provider = require '../oauth-provider/provider.coffee'
mongoose = require 'mongoose'

require './model/grant.coffee'
require './model/access-token.coffee'

class MongoOAuthProvider extends Provider
  constructor: (config) ->
    @db =
      user: mongoose.model 'user'
      client: mongoose.model 'client'
      grant: mongoose.model 'grant'
      accessToken: mongoose.model 'accessToken'

    @exchangeMethods = ['basic', 'oauth2-client-password']

    super config

  getCode: (length)-> Provider.uid()

  issueGrantCode: (client, redirectURI, user, ares, callback) ->
    code = @getCode(16)
    grant = new @db.grant {
      code
      redirectURI
      client: client.id
      user: user.id
    }

    grant.save (err)->
      return callback err if err
      callback null, code

  issueImplicitToken: (client, user, ares, callback) ->
    code = @getCode(32)
    accessToken = new @db.accessToken {
      token: code
      client: client.clientId
      user: user.id
    }

    accessToken.save (err)->
      return callback err if err
      callback null, code

  exchangeCodeForToken: (client, code, redirectURI, done) ->
    @db.grant.findOne {code}, (err, grant)=>
      return done err if err
      return done err, false if client.id isnt grant.client or redirectURI isnt grant.redirectURI

      token = @getCode()
      accessToken = new @db.accessToken {
        token
        user: grant.user
        client: grant.client
      }

      accessToken.save (err)->
        return done err if err
        done null, token

  exchangePasswordForToken: (client, username, password, scope, done) ->
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
      token = @getCode()
      accessToken = new @db.accessToken {
        token
        user: user.id
        client: clientId
      }

      accessToken.save()
      return token
    , done


  findClient: (clientId, redirectURI, cb)->
    @db.client.findOne {clientId}, (err, client)->
      return cb err if err
      ## WARNING: For security purposes, it is highly advisable to check that
      ##          redirectURI provided by the client matches one registered with
      ##          the server.  For simplicity, this example does not.  You have
      ##          been warned.
      cb null, client, redirectURI


  ## serialize client into session storage (can be overwrite)
  serialize: (client, done)-> done null, client.id

  ## deserialize client from session storage (can be overwrite)
  deserialize: (id, done)->
    ## get client (consumer)
    @db.client.findById id, (err, client)->
      return done err if err
      done null, client

module.exports = MongoOAuthProvider