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
    console.error('uuid is not a string')
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
  constructor (code, resultCallback) {
    this._code = code

    this._imports = {
      log: this.log,
      fetch: this.fetch,

      finalResult: function (err, uuid, resultString) {
        resultCallback(err, uuid, resultString)
      }
    }

    this._resultCallback = resultCallback

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

  execute (uuid, ...args) {
    let codeString

    try {
      codeString = postCode(uuid, args)
    } catch (e) {
      console.error(e)
      this._resultCallback(e, null, null)
      return
    }

    const compiledCode = this._compile(codeString)
    this._run(compiledCode, 'execute.js')
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
