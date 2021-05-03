# AccessLogApp

Processes a log file hosted as a Github Gist

## How to use

Clone the repo
`git clone https://github.com/bigbassroller/acces-log-app`

Change into the directory
`cd acces-log-app`

Install dependencies
`mix deps.get`

Go into interactive shell
`iex -S mix`

and run this command
`AccessLogApp.CLI.fetch`

For interations and debugging:
`clear && recompile && AccessLogApp.CLI.fetch`
