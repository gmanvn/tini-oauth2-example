express = require 'express'
app = express()
passport = require 'passport'
Provider = require '../oauth-provider/provider.coffee'

provider = new Provider {}

## routes
site = require './routes/site.coffee'
user = require './routes/user.coffee'

app.set 'view engine', 'jade'
app.use express.logger()
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session({ secret: 'keyboard cat' })

app.use passport.initialize()
app.use passport.session()
app.use app.router
app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.get "/", site.index
app.get "/login", site.loginForm
app.post "/login", site.login
app.get "/logout", site.logout
app.get "/account", site.account

app.get "/dialog/authorize", provider.authorization()
app.post "/dialog/authorize/decision", provider.decision()

app.post "/oauth/token", oauth2.token
app.get "/api/userinfo", user.info
app.get "/api/clientinfo", client.info