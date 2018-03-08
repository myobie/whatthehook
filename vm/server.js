const fs = require('fs')
const { Port } = require('./port')
const { inspect } = require('util')

const _log = fs.createWriteStream('./debug.log')
const endsWithNewline = /\n$/

function log (msg) {
  if (!endsWithNewline.test(msg)) {
    msg = `${msg}\n`
  }
  msg = `${new Date()} ${msg}`
  _log.write(msg)
}

log('starting up...')

const port = new Port({ log })

port.on('error', e => {
  log(`error! ${inspect(e)}`)
})

port.on('finish', () => {
  log('finishing...')
})

process.stdin.pipe(port).pipe(process.stdout)
