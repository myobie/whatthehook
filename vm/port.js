const { Transform } = require('stream')
const { Erlang } = require('erlang_js')

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

class Port extends Transform {
  constructor (options = {}) {
    const _log = options.log
    delete options.log

    super(options)

    if (_log) { this.log = _log }

    this.readUntil = 0
    this.buffer = Buffer.from('')
    this.outbound = []
    this.isReading = false
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

      Promise.all(subChunks.map(s => {
        binaryToTerm(s)
          .then(term => {
            termToBinary('ok')
              .then(t => this.push(t))
              .catch(() => {})

            this.emit('term', term)
          })
          .catch(e => Promise.reject(e))
      }))
        .then(() => cb())
        .catch(e => cb(e))

      this.log(`leftovers are ${this.buffer} | ${this.readUntil}`)

      this.log('done with this chunk')
    } catch (e) {
      return cb(e)
    }
  }

  async send (term) {
    return termToBinary(term)
      .then(b => {
        this.log('about to push msg...')

        const len = Buffer.alloc(4)
        len.writeUInt32BE(b.length, 0)

        const msg = Buffer.concat([len, b])

        this.push(msg)

        return Promise.resolve('ok')
      })
      .catch(e => Promise.reject(e))
  }
}

module.exports = {
  Port
}
