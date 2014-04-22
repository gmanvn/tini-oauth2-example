config = require 'config'
express = require 'express'
app = express()
passport = require 'passport'
logger = require('log4js').getLogger('app.coffee')

mongoose = require 'mongoose'
mongoose.connect config.mongo.connection

require './auth.coffee'

middlewares = [
  require('cookie-parser')()
  require('body-parser')()
  require('express-session')({ secret: 'keyboard cat' })
]

model=
  user: require './model/user.coffee'
  client: require './model/client.coffee'

require('./init-data.coffee') mongoose, ()->

Provider = require './custom-oauth-provider.coffee'
provider = new Provider {}

## routes
site = require './routes/site.coffee'
user = require './routes/user.coffee'
client = require './routes/client.coffee'

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'


app.use middleware for middleware in middlewares

app.use passport.initialize()
app.use passport.session()
#app.use app.router
#app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.get "/", site.index
app.get "/login", site.loginForm
app.post "/login", site.login
app.get "/logout", site.logout
app.get "/account", site.account

app.get "/dialog/authorize", provider.authorization()
app.post "/dialog/authorize/decision", provider.decision()

app.post "/oauth/token", provider.token()
app.get "/api/userinfo", user.info
app.get "/api/clientinfo", client.info

exports.start = (cb = ->)->
  @mode = app.get 'env'
  @port = config.provider.port
  @http = app.listen @port

  logger.debug "App start listening on #{@port} - mode: #{@mode}"
