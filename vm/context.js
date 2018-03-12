const vm = require('vm')
const { inspect } = require('util')

function getMethods (obj) {
  var res = []
  for (var m in obj) {
    if (typeof obj[m] === 'function') {
      res.push(m)
    }
  }
  return res
}

const sandbox = {
  dir: function (what) {
    console.dir(what)
    console.log(inspect(what))
    console.log(what.name)
    console.dir(Object.keys(what))
    console.dir(Object.keys(what.prototype))
    console.dir(getMethods(what))
    console.dir(getMethods(what.prototype))
  },
  fetch: function () {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        // reject(new Error('request failed'))
        resolve({})
      }, 1000)
    })
  }
}

const setupStateCode = `
  'use strict'

  var global = this

  Object.setPrototypeOf(global, Object.prototype)

  Object.defineProperties(global, {
    constructor: { value: Object },
    global: {value: global},
    GLOBAL: {value: global},
    root: {value: global},
    isVM: {value: true}
  })

  const sandboxKeys = [${Object.keys(sandbox).map(n => `'${n}'`).join(',')}]

  sandboxKeys.forEach(name => {
    let o = this[name]
    let klass

    if (typeof o === 'function') {
      klass = Function
    } else {
      klass = Object
    }

    Object.defineProperties(o, {
      constructor: { value: klass },
      __proto__: { value: klass.prototype },
      prototype: { value: klass.prototype }
    })
  })

  var state = {}
  var module = { exports: undefined }
  var result = undefined
  var error = undefined
  var currentArguments = []
`

let setupStateScript
try {
  setupStateScript = new vm.Script(setupStateCode, { filename: 'user.js', timeout: 5000, displayErrors: true })
} catch (e) {
  console.error('code compilation for setup state code failed', e)
  process.exit(1)
}

const userSuppliedCode = `
  'use strict'

  // this.constructor.constructor('return process')().exit()
  // fetch.constructor.constructor('return process')().exit()

  module.exports = async function () {
    // while (true) { 1 }
    return await fetch('https://github.com/myobie.keys')
  }
`

let userSuppliedScript
try {
  userSuppliedScript = new vm.Script(userSuppliedCode, { filename: 'user.js', timeout: 5000, displayErrors: true })
} catch (e) {
  console.error('code compilation for user supplied code failed', e)
  process.exit(1)
}

const postCode = `
  'use strict'

  Promise.resolve(module.exports.apply(null, currentArguments))
    .then(r => { result = JSON.stringify(r) })
    .catch(e => { error = e })
`

let postScript
try {
  postScript = new vm.Script(postCode, { filename: 'user.js', timeout: 5000, displayErrors: true })
} catch (e) {
  console.error('code compilation for post code failed', e)
  process.exit(1)
}

const context = vm.createContext(sandbox)

module.exports = async function runTestInContext () {
  try {
    Promise.resolve({})
      .then(() => {
        Promise.resolve(setupStateScript.runInContext(context, { filename: 'user.js', timeout: 5000, displayErrors: true }))
      })
      .then(() => {
        Promise.resolve(userSuppliedScript.runInContext(context, { filename: 'user.js', timeout: 5000, displayErrors: true }))
      })
      .then(() => {
        return Promise.resolve(postScript.runInContext(context, { filename: 'user.js', timeout: 5000, displayErrors: true }))
      })
      .then(() => {
        console.dir(sandbox)
      })
      .catch(e => {
        console.error('execution error in async', e)
      })
  } catch (e) {
    console.error('execution error', e)
  }
}
