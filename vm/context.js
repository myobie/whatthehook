/*
 * TODO
 * - Make a state machine so the context can only be prepared once
 * - Make sure we are prepared before executing
 * - When a callback comes into execute, store it in a dictionary with it's
 *   uuid and then match that uuid in the finalResult function so we can
 *   support multiple pending callbacks
*/

const vm = require('vm')
const { inspect } = require('util')

const setupCode = `
  'use strict'

  var global = this

  contextify(global)
  contextify(this)

  Object.defineProperties(global, {
    global: {value: global},
    GLOBAL: {value: global},
    root: {value: global},
    isVM: {value: true}
  })

  for (let i in global._imports) {
    global[i] = contextify(global._imports[i])
  }

  delete global._imports

  var result = undefined
  var error = undefined
  var currentArguments = []
  var module = { exports: undefined }

  function contextify (o) {
    let klass

    if (typeof o === 'function') {
      klass = Function
    } else {
      klass = Object
    }

    Object.setPrototypeOf(o, klass.prototype)

    Object.defineProperties(o, {
      constructor: { value: klass }
    })

    return o
  }
`

function postCode (uuid, args) {
  if (typeof uuid !== 'string') {
    throw new Error('uuid is not a string')
  }

  return `
    'use strict'

    ;(function () {
      const uuid = '${uuid}'

      try {
        const currentArguments = ${JSON.stringify(args)}

        Promise.resolve(request(...currentArguments))
          .then(r => {
            try {
              log('finalResult: ' + JSON.stringify(r))
              finalResult(null, uuid, JSON.stringify(r))
            } catch (e) {
              log('result returned from request is invalid')
            }
          })
          .catch(e => {
            try {
              finalResult(e, uuid, null)
            } catch (wow) {
              log('An unrecoverable error occured')
              log(wow)
            }
          })
      } catch (e) {
        finalResult(e, uuid, null)
      }
    })()
  `
}

module.exports = class Context {
  constructor (code, resultCallback, options = {}) {
    this._code = code
    const _externalLog = options.log
    this._externalLog = _externalLog

    const _internalFetch = this.fetch.bind(this)

    const _imports = {
      log: function (what) {
        if (_externalLog) { _externalLog(what) }
      },

      fetch: function (...args) {
        return _internalFetch(...args)
      },

      finalResult: function (err, uuid, resultString) {
        resultCallback(err, uuid, resultString)
      }
    }

    this._resultCallback = resultCallback

    const _sandbox = Object.create(null)
    _sandbox._imports = _imports

    this.timeout = 5000
    this._context = vm.createContext(_sandbox)
  }

  log (what) {
    if (this._externalLog) { this._externalLog(what) }
  }

  fetch () {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        // reject(new Error('request failed'))
        resolve({status: 500, body: ''})
      }, 1000)
    })
  }

  prepare () {
    const setup = this._compile(setupCode, 'setup.js')
    this._run(setup)

    const user = this._compile(this._code, 'user.js')
    this._run(user)
  }

  execute (uuid, ...args) {
    let codeString

    try {
      codeString = postCode(uuid, args)
    } catch (e) {
      this.log(inspect(e))
      this._resultCallback(e, null, null)
      return
    }

    const compiledCode = this._compile(codeString)
    this._run(compiledCode, 'execute.js')
  }

  _compile (code, filename) {
    this.log(`compiling code:
${code}
`)
    try {
      return new vm.Script(code, { filename, timeout: this.timeout, displayErrors: true })
    } catch (e) {
      this.log(`code compilation failed: ${inspect(e)}`)
      throw e
    }
  }

  _run (script, filename) {
    try {
      return script.runInContext(this._context, { filename, timeout: this.timeout, displayErrors: true })
    } catch (e) {
      this.log(`execution error: ${inspect(e)}`)
      throw e
    }
  }
}
