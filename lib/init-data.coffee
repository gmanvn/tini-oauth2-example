fibrous = require 'fibrous'

module.exports = fibrous (mongoose)->
  console.log 'initializing data'
  #console.log 'initUser', initUser
  initUser.sync mongoose
  initClient.sync mongoose



initUser = fibrous (mongoose)->
  console.log 'initializing user'
  User = mongoose.model 'user'
  count = User.sync.count()
  console.log 'count', count
  return unless count is 0

  ## count = 0
  admin = new User {
    username: 'admin'
    password: 'admin'
    name: 'Admin'
  }

  guest = new User {
    username: 'guest'
    password: 'guest'
    name: 'Guest'
  }

  admin.sync.save()
  guest.sync.save()
  console.log '2 users created'

initClient = fibrous (mongoose)->
  Client = mongoose.model 'client'
  count = Client.sync.count()
  return unless count is 0

  ## count = 0
  app1 = new Client {
    clientId: 'awesome-app'
    clientSecret: 'awesome-secret'
    name: 'Awesome'
  }

  app1.sync.save()
  console.log '1 client created'
