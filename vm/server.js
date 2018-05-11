const fs = require('fs')
const { Port } = require('./port')
const { inspect } = require('util')
const Context = require('./context')

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

let counter = 0

function nextCounter () {
  counter += 1
  return String(counter)
}

function callback (term, next) {
  log('callback!')

  try {
    const c = new Context(term, (err, uid, result) => {
      if (err) {
        next(['error', uid, inspect(err)])
      } else {
        try {
          next(['ok', uid, result])
        } catch (e) {
          next(['error', uid, inspect(e)])
        }
      }
    }, { log })
    c.prepare()
    c.execute(nextCounter(), {})
    log('context created and will send result')
  } catch (e) {
    log(`There was an error ${inspect(e)}`)
    next(['error', `There was an error ${inspect(e)}`])
  }
}

const port = new Port({ log, callback })

port.on('error', e => {
  log(`error! ${inspect(e)}`)
})

port.on('finish', () => {
  log('finishing...')
})

process.stdin.pipe(port).pipe(process.stdout)
