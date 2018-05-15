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

let context

function callback (term, next) {
  log('callback!')

  const json = JSON.parse(term)

  if (json.type === 'prepare') {
    prepare(json.code, next)
  } else if (json.type === 'execute') {
    execute(json.args, json.uuid, next)
  } else {
    next(['error', 'unknown message'])
  }
}

function prepare (code, next) {
  if (context !== undefined) {
    next(['error', 'context already prepared'])
    return
  }

  try {
    context = new Context(code, { log })
    context.prepare()
    next(['ok', 'prepared'])
  } catch (e) {
    log(`There was an error ${inspect(e)}`)
    next(['error', `There was an error ${inspect(e)}`])
  }
}

function execute (args, uuid, next) {
  if (context === undefined) {
    next(['error', 'context unprepared'])
    return
  }

  try {
    context.execute(args, uuid, (err, result) => {
      try {
        if (err) {
          next(['error', uuid, inspect(err)])
        } else {
          next(['ok', uuid, result])
        }
      } catch (e) {
        next(['error', uuid, inspect(e)])
      }
    })
  } catch (e) {
    log(`There was an error ${inspect(e)}`)
    next(['error', uuid, `There was an error ${inspect(e)}`])
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
