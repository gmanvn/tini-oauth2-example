###
Module dependencies.
###
passport = require("passport")
login = require("connect-ensure-login")
exports.index = (req, res) ->
  res.send "OAuth 2.0 Server"
  return

exports.loginForm = (req, res) ->
  res.render "login"
  return

exports.login = passport.authenticate("local",
  successReturnToOrRedirect: "/"
  failureRedirect: "/login"
)
exports.logout = (req, res) ->
  req.logout()
  res.redirect "/"
  return

exports.account = [
  login.ensureLoggedIn()
  (req, res) ->
    res.render "account",
      user: req.user

]