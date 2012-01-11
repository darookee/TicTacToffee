module.exports =
    body:
        margin: '0 auto'
        marginTop: '25px'
        width: '400px'
        textAlign: 'center'
    'div#gameField':
        margin: '0 auto'
        width: '95px'
    table:
        tr:
            td:
                width: '25px'
                height: '25px'
                border: 'solid 1px black'
                backgroundImage: 'url( /xo.png )'
                backgroundPosition: '-50px -50px'
                backgroundRepeat: 'no-repeat'
            'td.X':
                backgroundPosition: '0 0'
            'td.O':
                backgroundPosition: '-28px -1px'
            'td:first-child':
                borderLeft: 'none'
            'td:last-child':
                borderRight: 'none'
        'tr:first-child':
            td:
                borderTop: 'none'
        'tr:last-child':
            td:
                borderBottom: 'none'
    button:
        border: 'solid 1px red'
        background: '#ffffff'
        margin: '5px'
