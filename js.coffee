connect = () ->
    window.ttSocket = {}
    window.ttSocket.main = io.connect()
    window.ttSocket.game = window.ttSocket.main.of '/game'
    window.ttSocket.game.on 'gameCreated', connected
    window.ttSocket.game.on 'gotOpponent', opponentConnected
    window.ttSocket.game.on 'joinedGame', connectedJoin
    window.ttSocket.game.on 'noFreeGame', noFree
    window.ttSocket.game.on 'receiveMove', receiveMove
    window.ttSocket.game.on 'endGame', endGame
    window.ttSocket.game.on 'disco', opponentLeft

setup = () ->
    $( 'button#newGame' ).on 'click', newGame
    $( 'button#joinGame' ).on 'click', joinGame

newGame = () ->
    window.ttSocket.game.emit 'newGame'

joinGame = () ->
    window.ttSocket.game.emit 'joinGame'

setGameData = ( data ) ->
    if window.gameData? and window.gameData.player?
        player = window.gameData.player
    window.gameData = data
    window.gameData.player = player if not data.player?

setStatus = ( message ) ->
    status = $ 'div#status'
    status.text message

connected = ( data ) ->
    setGameData data
    createField()
    setStatus data.message if data.message?

connectedJoin = ( data ) ->
    setGameData data
    createField()
    setStatus data.message if data.message?

noFree = ( data ) ->
    setGameData data
    setStatus data.message

opponentConnected = ( data ) ->
    setGameData data
    setStatus data.message if data.message?

opponentLeft = ( data ) ->
    setGameData data
    setStatus data.message if data.message?

receiveMove = ( data ) ->
    setGameData data
    setClass key, player for own key, player of data.field
    setStatus data.message if data.message?

endGame = ( data ) ->
    setGameData data
    setStatus data.message if data.message?

setClass = ( key, player ) ->
    $( 'td#' + key ).addClass( player )

createField = () ->
    fieldDiv = $ '#gameField'
    field = $ '<table><tr><td id="11"></td><td id="12"></td><td id="13"></td></tr><tr><td id="21"></td><td id="22"></td><td id="23"></td></tr><tr><td id="31"></td><td id="32"></td><td id="33"></td></tr></table>'
    fieldDiv.html ''
    field.appendTo fieldDiv
    cells = field.find 'td'
    cells.on 'click', sendClick

sendClick = ( e ) ->
    if window.gameData.enabled == true
        clickedID = $( e.target ).attr 'id'
        window.ttSocket.game.emit 'sendMove', { cell: clickedID, gameId: window.gameData.gameId, player: window.gameData.player }

$( 'document' ).ready () ->
    connect()
    setup()
