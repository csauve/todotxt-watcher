require "cson"
http = require "http"
fs = require "fs"
serveStatic = require "serve-static"
config = require "config"
parser = require "todotxt-parser"
express = require "express"
io = require "socket.io"

tasks = []
clients = {}

readTasks = (cb) ->
  console.log "Reading tasks"
  fs.readFile config.todoFile, encoding: "UTF-8", (err, data) ->
    return cb err if err
    tasks = parser.relaxed data,
      hierarchical: true, inherit: true
    cb()

readTasks (err) ->
  throw err if err

fs.watch config.todoFile, ->
  readTasks (err) ->
    throw err if err
    for id, socket of clients
      socket.emit "update", tasks

app = express()
app.use "/", serveStatic "client", config.static
server = http.createServer app

io(server).on "connection", (socket) ->
  console.log "Client connected"
  clients[socket.id] = socket
  socket.emit "update", tasks

  socket.on "disconnect", ->
    console.log "Client disconnected"
    delete clients[socket.id]

server.listen config.port
console.log "Listening on port #{config.port}"
