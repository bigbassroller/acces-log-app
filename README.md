# AccessLogApp

https://gist.githubusercontent.com/clanchun/2b5e07cda53718ccbf64f62fb31900c8/raw/64be7f018973717dd5faa7be2bfb817f50ed05bb/access.log

Write a script that does the following:

1. Parse access.log file hosted as gist
2. Get tcp_hit percentage per video id
3. Sort by video id (video id is an integer)
4. print to console or write to file
5. add tests if there is still time

there are two different url formats to handle:

http://c13.adrise.tv/04C0BF/v2/sources/content-owners/cinedigm-tubi/384055/v201708302148-2273k.mp4+4023936.ts

http://c13.adrise.tv/04C0BF/ads/transcodes/006817/2791522/v0402000243-854x480-HD-1401k.mp4+22355.ts

example line:
1523756544 3 86.45.165.83 1845784 152.195.141.240 80 TCP_HIT/200 1846031 GET http://c13.adrise.tv/04C0BF/v2/sources/content-owners/sgl-entertainment/275211/v0401185814-1389k.mp4+740005.ts - 0 486 "-" "TubiExoPlayer/2.12.9 (Linux;Android 6.0) ExoPlayerLib/2.4.2" 49343 "-"

lines


cache hit/miss:
TCP_HIT

video id:
275211

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
