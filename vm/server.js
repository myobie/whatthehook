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

port.on('term', t => {
  log(`term: ${inspect(t)}`)
})

port.on('error', e => {
  log(`error! ${inspect(e)}`)
})

let counter = 1

let intervalNumber = setInterval(() => {
  port
    .send({ counter })
    .then(r => log(`send result: ${inspect(r)}`))
    .catch(e => log(`send error: ${inspect(e)}`))

  counter += 1
}, 10000)

port.on('finish', () => {
  clearInterval(intervalNumber)
  log('finishing...')
})

process.stdin.pipe(port).pipe(process.stdout)

process.stdout.resume()
