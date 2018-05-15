%WTH.Webhooks.Hook{
  endpoint: "example.com",
  code: """
function request (req) {
  const counter = req.state.counter || 0;

  return fetch('http://google.com')
    .then(res => {
      res.state = { counter: counter + 1 }
      return res
    })
}
"""
}
|> WTH.Repo.insert!()
