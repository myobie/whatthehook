const { Transform } = require('stream')
const { Erlang } = require('erlang_js')
const { inspect } = require('util')

function getSize (binary) {
  const sizeBinary = binary.slice(0, 4)
  const size = sizeBinary.readUInt32BE(0, true)

  if (size > 0) {
    binary = binary.slice(4)
  }

  return [size, binary]
}

function readSize (binary, size) {
  const subBinary = binary.slice(0, size + 1)
  binary = binary.slice(size + 1)
  const newSize = size - subBinary.length
  return [binary, subBinary, newSize]
}

function binaryToTerm (binary) {
  return new Promise((resolve, reject) => {
    try {
      Erlang.binary_to_term(binary, (err, term) => {
        if (err) {
          reject(err)
        } else {
          resolve(term)
        }
      })
    } catch (e) {
      reject(e)
    }
  })
}

function termToBinary (term) {
  return new Promise((resolve, reject) => {
    try {
      Erlang.term_to_binary(term, (err, binary) => {
        if (err) {
          reject(err)
        } else {
          resolve(binary)
        }
      })
    } catch (e) {
      reject(e)
    }
  })
}

function after (delay, cb) {
  return new Promise((resolve, reject) => {
    try {
      setTimeout(() => {
        resolve(cb())
      }, delay)
    } catch (e) {
      reject(e)
    }
  })
}

class Port extends Transform {
  constructor (options = {}) {
    const _log = options.log
    delete options.log

    const _callback = options.callback
    delete options.callback
    delete options.cb

    super(options)

    if (_log) { this.log = _log }

    if (_callback) {
      this.callback = _callback
    } else {
      this.callback = function (term) {
        return after(1000, () => term)
      }
    }

    this.buffer = Buffer.from('')
    this.readUntil = 0
  }

  log () {}

  _transform (chunk, encoding, cb) {
    try {
      let readUntil = this.readUntil
      let subChunks = []

      chunk = Buffer.from(chunk)

      this.log('incoming...')

      while (readUntil < chunk.length) {
        let subChunk

        if (readUntil === 0) {
          [readUntil, chunk] = getSize(chunk)
        }

        [chunk, subChunk, readUntil] = readSize(chunk, readUntil)

        subChunks.push(subChunk)
      }

      this.buffer = chunk
      this.readUntil = readUntil

      this.log(`leftovers are ${this.buffer} | ${this.readUntil}`)

      const send = this.send.bind(this)

      if (subChunks.length > 0) {
        subChunks.map(s => {
          binaryToTerm(s)
            .then(term => {
              term = String(term.value)
              this.log('received msg and invoking port callback')
              this.log(`=> ${inspect(term)}`)

              this.callback(term, result => {
                send(result)
                  .then(() => {
                    this.log('next')
                    cb()
                  })
                  .catch(e => {
                    this.log(`error sending: ${inspect(e)}`)
                    cb(e)
                  })
              })
            })
            .catch(e => {
              this.log(`problem reading sent binary chunk: ${inspect(e)}`)
              cb(e)
            })
        })
      } else {
        cb()
      }

      this.log('done with this chunk')
    } catch (e) {
      this.log(`outermost catch: ${inspect(e)}`)
      cb(e)
    }
  }

  async send (term) {
    this.log(`sending back term ${inspect(term)}`)

    return termToBinary(term)
      .then(b => {
        this.log('about to push msg...')

        const len = Buffer.alloc(4)
        len.writeUInt32BE(b.length, 0)

        const msg = Buffer.concat([len, b])

        this.log(`sending: ${inspect(msg)}`)

        this.push(msg)

        return Promise.resolve(msg)
      })
      .catch(e => Promise.reject(e))
  }
}

module.exports = {
  Port
}
