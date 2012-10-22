express = require 'express'
connect = require 'connect'
http = require 'http'

ccss = require 'ccss'
coffeekup = require 'coffeekup'
coffeescript = require 'coffee-script'

sio = require 'socket.io'

views =
    main: ->
        doctype 5
        html ->
            head ->
                meta charset: 'utf-8'
                title 'TicTacToe'
                link rel: 'stylesheet', type: 'text/css', href: '/app.css'
                script src: '//ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js'
                script src: '/socket.io/socket.io.js'
                script src: '/app.js'
            body ->
                div id: 'gameField'
                button id: 'newGame', ->
                    'New'
                button id: 'joinGame', ->
                    'Join'
                div id: 'status'

app = express()
server = http.createServer(app)

app.configure () ->
    app.use app.router
    app.use connect.static __dirname + '/public'
    app.use connect.favicon __dirname + '/public/favicon.ico'
    true

app.get '/', ( req, res ) ->
    res.send coffeekup.render views.main

app.get '/app.css', ( req, res ) ->
    ccssTemplate = require './css.coffee'
    res.setHeader 'Content-Type', 'text/css'
    res.send ccss.compile ccssTemplate

app.get '/app.js', ( req, res ) ->
    fs = require 'fs'
    coffeeJS = fs.readFileSync './js.coffee', 'ascii'
    res.setHeader 'Content-Type', 'text/javascript'
    res.send coffeescript.compile coffeeJS

io = sio.listen server
io.enable 'browser client minification'
io.enable 'browser client etag'
io.enable 'browser client gzip'
io.set 'log level', 2
logger = io.log

chatSocket = io.of '/chat'
gameSocket = io.of '/game'

clients = []
games = []
freeGames = []

createGame = ( gameData, socket ) ->
    gameId = games.push gameData
    gameId--
    freeGames.push gameId
    socket.emit 'gameCreated', gameNum: gameData.gameNum, gameId: gameId, player: 'X', enabled: false, message: 'Game ' + gameData.gameNum + ' created'
    logger.info 'Game ' + gameData.gameNum + ' created'
    myGame: gameId, myPlayer: 'X'

joinGame = ( socket ) ->
    gameId = freeGames.shift()
    if gameId?
        game = games[gameId]
        if game.X?
            games[gameId].O = socket.id
            clients[games[gameId].X].emit 'gotOpponent', gameNum: game.gameNum, gameId: gameId, player: 'X', enabled: true, message: 'Player joined'
            socket.emit 'joinedGame', gameNum: game.gameNum, gameId: gameId, player: 'O', enabled: false, message: 'Joined game ' + game.gameNum
            { myGame: gameId, myPlayer: 'O' }
    else
        socket.emit 'noFreeGame', message: 'No free game'

sendMove = ( data ) ->
    if games[data.gameId]
        games[data.gameId].cells[data.cell] = data.player if not games[data.gameId].cells[data.cell]?
        won = checkWin games[data.gameId].cells, data.player
        games[data.gameId].wonPlayer = won
        xEnabled = if data.player == 'O' then true else false
        oEnabled = if data.player == 'X' then true else false
        eventDataX = field: games[data.gameId].cells, gameNum: games[data.gameId].gameNum, gameId: data.gameId, enabled: xEnabled, message: if xEnabled then 'Your turn' else 'Waiting for O'
        eventDataO = field: games[data.gameId].cells, gameNum: games[data.gameId].gameNum, gameId: data.gameId, enabled: oEnabled, message: if oEnabled then 'Your turn' else 'Waiting for X'
        clients[games[data.gameId].X].emit 'receiveMove', eventDataX
        clients[games[data.gameId].O].emit 'receiveMove', eventDataO
        if won != false then endGame data.gameId
    else
        socket.emit 'noFreeGame'

endGame = ( gameId ) ->
    eventData =
        gameId: gameId,
        gameNum: games[gameId].gameNum,
        message: if games[gameId].wonPlayer == 'tie' then 'Tie' else games[gameId].wonPlayer + ' won the game',
        enabled: false,
        wonPlayer: games[gameId].wonPlayer
    clients[games[gameId].X].emit 'endGame', eventData if clients[games[gameId].X]?
    clients[games[gameId].O].emit 'endGame', eventData if clients[games[gameId].O]?
    logger.info 'Game ' + eventData.gameNum + ' ended - ' + eventData.wonPlayer + ' won'

disconnectPlayer = ( socket, myGame, myPlayer ) ->
    delete clients[socket.id]
    if myGame?
        delete games[myGame][myPlayer]
        myOpponent = if myPlayer == 'X' then 'O' else 'X'
        if clients[games[myGame][myOpponent]]?
            clients[games[myGame][myOpponent]].emit 'disco', gameId: myGame, gameNum: games[myGame].gameNum, message: myPlayer + ' disconnected'

checkWin = ( cells, player ) ->
    winP = player + player + player
    win = false
    if cells['11'] + cells['22'] + cells['33'] == winP
        win = true
    if cells['13'] + cells['22'] + cells['31'] == winP
        win = true
    if cells['11'] + cells['12'] + cells['13'] == winP
        win = true
    if cells['21'] + cells['22'] + cells['23'] == winP
        win = true
    if cells['31'] + cells['32'] + cells['33'] == winP
        win = true
    if cells['11'] + cells['21'] + cells['31'] == winP
        win = true
    if cells['12'] + cells['22'] + cells['32'] == winP
        win = true
    if cells['13'] + cells['23'] + cells['33'] == winP
        win = true
    if cells['11']? and cells['12']? and cells['13']? and cells['21']? and cells['22']? and cells['23']? and cells['31']? and cells['32']? and cells['33']?
        win = true
        player = 'tie'
    if win == true then player else false

createGameNum = () ->
    String( Math.random() ).substr( -8 )

gameSocket.on 'connection', ( socket ) ->
    logger.info 'Client ' + socket.id + ' connected'
    clients[socket.id] = socket
    myGame = null
    myPlayer = null

    socket.on 'newGame', ( data ) ->
        myGameObject = createGame { X: socket.id, gameNum: createGameNum(), cells: {} }, socket
        myGame = myGameObject.myGame
        myPlayer = myGameObject.myPlayer

    socket.on 'joinGame', ( data ) ->
        myGameObject = joinGame socket
        if myGameObject?
            myGame = myGameObject.myGame
            myPlayer = myGameObject.myPlayer
        else
            myGame = null
            myPlayer = null

    socket.on 'sendMove', ( data ) ->
        sendMove data

    socket.on 'disconnect', ( data ) ->
        disconnectPlayer socket.id, myGame, myPlayer

server.listen 8319, () ->
    logger.info 'Listening on http://' + server.address().address + ':' + server.address().port
