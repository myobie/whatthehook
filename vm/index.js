const Context = require('./context')

const code = `
  'use strict'

  try {
    this.constructor.constructor('return process')().exit()
  } catch (e) {
    log('this hack failed')
    log(e)
  }

  try {
    fetch.constructor.constructor('return process')().exit()
  } catch (e) {
    log('fetch hack failed')
    log(e)
  }

  async function request ({ user }) {
    // while (true) { 1 }
    log('fetching ' + user)
    return await fetch('https://github.com/' + user + '.keys')
  }
`

const c = new Context(code, (err, result) => {
  if (err) {
    console.error('execution error', err)
  } else {
    console.log('result', result)
  }
})

// invoke once
c.prepare()
c.execute({ user: 'myobie' })

// invoke again
c.execute({ user: 'waht' })
