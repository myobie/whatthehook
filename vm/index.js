const vm = require('vm')

const sandbox = {
  module: {
    exports: undefined,
    complete: r => { console.log('final result', r) },
    error: e => { console.error('final error', e) }
  },
  global: { arguments: [], result: undefined },
  fetch: function () {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        reject(new Error('request failed'))
      }, 1000)
    })
  }
}

const code = `
  module.exports = async function () {
    // while (true) { 1 }
    return await fetch('https://github.com/myobie.keys')
  }
`

const postCode = `
  const result = Promise.resolve(module.exports.apply(null, global.arguments))
  result
    .then(r => module.complete(r))
    .catch(e => module.error(e))
`

let script
try {
  script = new vm.Script(code + postCode, { filename: 'user.js', timeout: 5000, displayErrors: true })
} catch (e) {
  console.error('code compilation error', e)
  process.exit(1)
}

const context = vm.createContext(sandbox)

try {
  script.runInContext(context, { filename: 'user.js', timeout: 5000, displayErrors: true })
} catch (e) {
  console.error('execution error', e)
}
