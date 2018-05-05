const vm = require('vm')
const { inspect } = require('util')

const setupCode = `
  'use strict'

  var global = this

  Object.defineProperties(global, {
    global: {value: global},
    GLOBAL: {value: global},
    root: {value: global},
    isVM: {value: true}
  })

  contextify(global)

  for (let i in global._imports) {
    global[i] = contextify(global._imports[i])
  }

  delete global._imports

  var state = {}

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

const postCode = `
  'use strict'

  // TODO: add a try/catch in there
  try {
    Promise.resolve(request(...currentArguments))
      .then(r => {
        try {
          finalResult(null, JSON.stringify(r))
        } catch (e) {
          log('result returned from request is invalid')
        }
      })
      .catch(e => {
        try {
          finalResult(e, null)
        } catch (wow) {
          log('An unrecoverable error occured')
          log(wow)
        }
      })
  } catch (e) {
    finalResult(e, null)
  }
`

module.exports = class Context {
  constructor (code, resultCallback) {
    this._code = code

    this._imports = {
      log: this.log,
      fetch: this.fetch,

      // FIXME: this means we can only ever do one thing at a time
      //        instead we should have a UUID for every request and use
      //        that to corollate results
      finalResult: function (err, resultString) {
        resultCallback(err, resultString)
      }
    }

    this.timeout = 5000
    this._sandbox = {_imports: this._imports}
    this._context = vm.createContext(this._sandbox)
  }

  log (what) {
    console.log(inspect(what))
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

  execute (...args) {
    try {
      this._run(this._compile(`
        'use strict'
        currentArguments = ${JSON.stringify(args)}
      `), 'arguments.js')

      this._run(this._compile(postCode, 'execute.js'))
    } catch (e) {
    }
  }

  _compile (code, filename) {
    console.log(`compiling code:
${code}
`)
    try {
      return new vm.Script(code, { filename, timeout: this.timeout, displayErrors: true })
    } catch (e) {
      console.error('code compilation failed', e)
      throw e
    }
  }

  _run (script, filename) {
    try {
      return script.runInContext(this._context, { filename, timeout: this.timeout, displayErrors: true })
    } catch (e) {
      console.error('execution error', e)
      throw e
    }
  }
}
