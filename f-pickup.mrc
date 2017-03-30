; F-pickup 1.0 beta 8/7/2004
; Written by Fabian
; http://zap.to/f-pickup

; Features of F-Pickup 1.1 beta 10/4/2007
; # Little update
; + added command: !maplist to show list of maps in the channel
; + added command: !topic <your motd here> to set the channels topic
; ! forgot to remove permission by certain ip on some commands, now fixed.
; + added command: !setmapprefix <prefix> (example: !setmapprefix ut4_) so users can vote using: !vote sanc or !vote casa instead of !vote ut4_sanc or !vote ut4_casa
;
;
; Features of F-Pickup 1.0 beta 8/7/2004
; # First public release of F-pickup 
; + basic pick-up commands such as !addme, !removeme
; + map voting
; + max player setting
; + flood protection
; + auto-rejoin pick-up channel every 10 minutes
; + automatic map loading on game server
; + automatic random password changing on game server for every new pick-up game
; # The last 2 features work in combination with Q3 RCON for MIRC written by: >V<Callista
; 
; # = comment
; + = new feature
; * = improved feature
; ! = fixed bug
; - = removed feature


alias addmap set %up.vote_maps $addtok(%up.vote_maps,$1,32) | echo * Added to map list: $1
alias removemap set %up.vote_maps $remtok(%up.vote_maps,$1,32) | echo * Removed from maplist: $1
alias viewmaps echo * %up.vote_maps
alias setmax if ($1 isnum) set %up.max $1 | echo * Maximum players is now set to: %up.max
alias pickupchannel if ($1) set %up.chan $1 | echo * Pickup channel is now set to: %up.chan
alias setmapprefix if ($1-) set %up.mapPrefix $1- | echo * Map prefix is now set to: %up.mapPrefix
alias operator_rcon {
  if (!$1) {
    echo Operator command !rcon is $iif(%up.operator_rcon,enabled,disabled)
    echo Use "/operator_rcon on" to enable the !rcon command for operators
    echo Use "/operator_rcon off" to disable the !rcon command for operators
  }
  if ($1 == on) { set %up.operator_rcon 1 | echo Operator command !rcon is now enabled }
  if ($1 == off) { set %up.operator_rcon 0 | echo Operator command !rcon is now disabled }

}

on *:start:{
  if (!%up.chan) {
    echo -s This seems to be your first time running F-Pickup or you have not configured it properly yet.
    echo -s Please configure the following settings:
    echo -s /server_settings <ip:port> <rconpass> (Example: /server_settings 123.123.123.123:29760 bunny)
    echo -s /pickupchannel <#channel> (Example: /pickupchannel #p1ckupchann3l)
    echo -s 
    echo -s And add maps to the maplist by using: /addmap <mapname> (Example: /addmap q3dm12)
    echo -s You can also view maps (/viewmaps) and remove maps (/removemap <mapname>)
    echo -s See the manual on http://f-pickup.fab1an.nl for more help. 
  }
}
on *:CONNECT: if (quake isin $server) pickup_start
alias pickup_start join %up.chan | .timerJOIN_AGAIN 0 600 join %up.chan  

alias reset_votes {
  var %i = 1
  while ($gettok(%up.vote_maps,%i,32)) {
    var %t.map = $ifmatch
    if ($2) set $+(%,up.vote_votable_,%t.map) $reptok($eval($+(%,up.vote_votable_,%t.map),3),$1,$2,32)
    elseif ($1) set $+(%,up.vote_votable_,%t.map) $remtok($eval($+(%,up.vote_votable_,%t.map),3),$1,32)
    else set $+(%,up.vote_votable_,%t.map) $null
    inc %i
  }
}

#busys off
on *:TEXT:!*:%up.chan: {
  floodx

  var %x = $1 | goto %x

  :!addme
  :!add
  :!join
  if ($nick isop #) goto voice_op
  if ($nick isvo #) halt
  :voice_op
  .timerM 1 1 ps A pickup game is being played right now, wait till next round to sign up. $+([,$duration($timer(RESETP).secs) remaining...,])
  halt

  :!setmap
  :!changemap
  if ($nick isop #) {
    .timer 1 1 q3rcon map $1-
    .timerB 1 1 ps Changed map to: $1-
  }
  halt

  :!rcon
  if ($nick isop #) {
    .timer 1 1 q3rcon $1-
    .timerB 1 1 ps Command sent to server.
  }
  halt

  :!lostpass
  :!forgotpass
  :!password
  :!pass
  :!pw
  if ($istok(%up.last_players,$nick,32)) {
    msg $nick Server address: %up.server password: %up.password
  }
  halt

  :!gameover
  :!finished
  if ($istok(%up.last_players,$nick,32)) {
    inc %up.gameover
    if ($calc($round($calc(%up.max / 2),0) - %up.gameover) <= 0) {
      reset_votes
      normalize
    }
    else {
      ps Thanks for playing $+($nick,$chr(44)) need $calc($round($calc(%up.max / 2),0) - %up.gameover) more to confirm that the game is over.
    }
  }
  halt

  :!reset_votes
  :!clearvotes
  :!resetvotes
  :!clear_votes
  if ($nick isop #) {
    reset_votes
    ps Votes cleared.
  }
  halt

  :!status
  :!map
  :!vote
  :!votes
  .timerM 1 1 ps A pickup game is being played right now. $+([,$duration($timer(RESETP).secs) remaining...,])
  halt

  :!reset
  :!clear
  if ($nick isop #) {
    var %i = 1 
    while ($nick(#,%i)) {
      if ($nick(#,%i) isvo #) mode # -v $nick(#,%i)
      inc %i
    }
    reset_votes
    normalize
  }
  halt

  :!setmax
  :!setmaxplayers
  if ($nick isop #) {
    var %i = 1 
    while ($nick(#,%i)) {
      if ($nick(#,%i) isvo #) mode # -v $nick(#,%i)
      inc %i
    }
    reset_votes
    set %up.max $2
    .timerB 1 1 ps Player limit changed to: %up.max
  }
  halt

  :!setprefix
  :!mapprefix
  :!prefix
  :!setmapprefix
  if ($nick isop #) {
    setmapprefix $2-
    .timerPREFIX 1 1 ps Map prefix changed to: $2-
  }
  halt

  :!kill
  :!disconnect
  :!close
  :!exit
  :!quit
  if ($nick isop #) {
    ps Disconnecting in 10 seconds... (!cancel to abort)
    .timerDESTRUCT 1 10 selfdestruct
  }
  halt

  :!cancel
  if ($nick isop #) && ($timer(DESTRUCT)) {
    .timerDESTRUCT off
    ps Cancelled.
  }
  halt

  :!help
  showHelp
  halt


  halt
  :%x
}
#busys end


alias check_upfull {
  if ($nick(%up.chan,0,v) < %up.max) { set %up.full 0 }
}


#free on
on *:TEXT:!*:%up.chan: {
  floodx

  var %x = $1 | goto %x

  :!addme
  :!add
  :!join
  if ($nick isop #) goto voice_op
  if ($nick isvo #) halt
  :voice_op

  if (%up.full) halt
  if ($nick($chan,0,v) == $calc(%up.max - 1)) { set %up.full 1 | .timerGG 1 10 check_upfull }

  mode # +v $nick
  .timerX 1 3 showinfo #

  halt


  :!setmap
  :!changemap
  if ($nick isop #) {
    .timer 1 1 q3rcon map $1-
    .timerB 1 1 ps Changed map to: $1-
  }
  halt

  :!rcon
  if ($nick isop #) {
    .timer 1 1 q3rcon $1-
    .timerB 1 1 ps Command sent to server.
  }
  halt

  :!removeme
  :!remove
  :!leave
  if ($nick !isvo #) halt
  mode # -v $nick
  unset $+(%vote.,$nick)
  .timerD 1 1 showinfo #
  halt

  :!vote
  :!map
  :!votes
  if ($nick isvo #) {
    if ($0 >= 3) { not $nick Wrong vote syntax. Example of the !vote command: !vote ut4_prague | halt }

    ; check if no map is entered to show stats
    if ($0 == 1) {
      ps $vote_test(x).echo
      halt
    }

    ; check if map is allowed or valid
    if ($istok(%up.vote_maps,$2,32)) { var %map = $2 }
    elseif ($istok(%up.vote_maps,$+(%up.mapPrefix,$2),32)) { var %map = $+(%up.mapPrefix,$2) }
    if (!$istok(%up.vote_maps,%map,32)) { ps Invalid map name, allowed maps are: %up.vote_maps | halt }

    ; check if user did not already vote
    var %i = 1
    while ($gettok(%up.vote_maps,%i,32)) {
      var %t.map = $ifmatch
      if ($istok($eval($+(%,up.vote_votable_,%t.map),2),$nick,32)) { not $nick You already voted! | halt }
      inc %i
    }

    ; add vote
    var %temp = $eval($+(%,up.vote_votable_,%map),3)
    set $+(%,up.vote_votable_,%map) $iif(%temp,%temp $nick,$nick)
    not $nick You voted for %map | halt
  }
  elseif ($0 == 1) {
    ps $vote_test(x).echo
    halt
  }
  halt

  :!reset_votes
  :!resetvotes
  :!clearvotes
  !!clear_votes
  if ($nick isop #) {
    reset_votes
    ps Votes cleared.
  }
  halt

  :!status
  var %y = $null
  var %i = 1 | while ($nick(#,%i,v)) { var %y = %y $ifmatch | inc %i } 
  if ($nick(#,0,v)) {
    not $nick Signed up players $+([,$nick(#,0,v),/,%up.max,]) : %y
  }
  else not $nick Nobody has signed up for a pickup game, to sign up type: !addme
  halt

  :!maplist
  :!maps
  :!showmaps
  :!map_list
  :!show_maps
  ps Available maps: %up.vote_maps $chr(124) Use !vote <map> to vote
  halt

  :!reset
  :!clear
  if ($nick isop #) {
    var %i = 1 
    while ($nick(#,%i)) {
      if ($nick(#,%i) isvo #) mode # -v $nick(#,%i)
      inc %i
    }
    reset_votes
    normalize
  }
  halt

  :!setmax
  :!setmaxplayers
  if ($nick isop #) {
    var %i = 1 
    while ($nick(#,%i)) {
      if ($nick(#,%i) isvo #) mode # -v $nick(#,%i)
      inc %i
    }
    reset_votes
    set %up.max $2
    .timerB 1 1 ps Player limit changed to: %up.max
  }
  halt

  :!setprefix
  :!mapprefix
  :!prefix
  :!setmapprefix
  if ($nick isop #) {
    mapprefix $2-
    .timerPREFIX 1 1 ps Map prefix changed to: $2-
  }
  halt

  :!kill
  :!disconnect
  :!exit
  :!quit
  if ($nick isop #) {
    ps Disconnecting in 10 seconds... (!cancel to abort) - Don't forgot to restore server password (Admins)
    .timerDESTRUCT 1 10 { selfdestruct }
  }
  halt

  :!topic
  :!motd
  if ($nick isop #) {
    set %up.topic $2-
    setTopic
  }
  halt

  :!cancel
  :!abort
  :!stop
  if ($nick isop #) && ($timer(DESTRUCT)) {
    .timerDESTRUCT off
    ps Cancelled.
  }
  halt

  :!help
  showHelp
  halt

  halt
  :%x
}

;on *:JOIN:%up.chan: if ($nick == $me) .timerTOPIC 1 10 setTopic
on *:NICK: reset_votes $nick $newnick
on *:QUIT: reset_votes $nick
on *:DEVOICE:%up.chan: reset_votes $vnick
on *:PART:%up.chan: reset_votes $nick
on *:KICK:%up.chan: reset_votes $nick

raw 352:*: haltdef | if ($left($7,1) == G) && ($6 isvo %up.chan) { mode %up.chan -v $6 | msg $6 You have been removed from the signed up player list because you went into away mode. } } | halt
raw 315:*: haltdef 
#free end


alias showHelp {
  ps Normal command samples: !addme, !removeme, !status, !maplist, !vote prague, !map
  ps Operator command samples: !setmaxplayers 10, !reset, !resetvotes, !setmapprefix ut4_, !disconnect, !abort
}

alias setTopic {
  topic %up.chan %up.topic
}

alias not .timer $+ $nick 1 1 .notice $1-

alias selfdestruct {
  part %up.chan 
  disconnect 
  exit
}

alias showinfo { 
  if ($nick($1,0,v) >= %up.max) {
    ps Game is about to start, waiting for last player(s) to cast vote (10 seconds)
    ps $vote_test(x).echo
    .timer 1 11 start_game $1-
    halt
  }
  var %y = $null | var %i = 1 | while ($nick($1,%i,v)) { var %y = %y $ifmatch | inc %i } 
  if ($nick($1,0,v)) {
    ; OLD WAY: ps Signed up players: $+([,$calc(%up.max - (%up.max - $nick($1,0,v))),/,%up.max,]) : %y
    ps Signed up players: $+([,$calc(%up.max - (%up.max - $nick($1,0,v))),/,%up.max,]) : type !status to see who is signed up.
  }
  else ps Nobody has signed up for a pickup game, to sign up type: !addme
}

alias floodx .timerY 1 1 set %flood 0 | inc %flood | if (%flood > 3) halt

alias private_message {
  var %i = 1
  while ($gettok($1-,%i,32)) {
    if ($istok(%up.captains,$gettok($1-,%i,32),32)) .timer 1 $calc(%i *3) .msg $gettok($1-,%i,32) $+(,$gettok($1-,%i,32),:) The pickup game is starting, go to the server and have a 1on1 knife fight with $+($remtok(%up.captains,$gettok($1-,%i,32),32),$chr(44)) the winner can choose a player first. Server ip: %up.server password: %up.password 
    else .timer 1 $calc(%i *3) .msg $gettok($1-,%i,32) $+(,$gettok($1-,%i,32),:) The pickup game is starting, go to the server and stay spectator until you are chosen by one of the captains. Server ip: %up.server password: %up.password 
    inc %i
  }
}

alias normalize .timerRESETP off | set %up.full 0 | .enable #free | .disable #busys | ps You can sign up again. 

alias switch_color {
  var %o = 1 
  while ($gettok(%t.votewinner,%o,32)) {
    if (%up.color.count == $gettok(%t.votewinner,%o,32)) { inc %up.color.count | return 0,3 }
    inc %o
  }
  if (%up.color == 1) { inc %up.color.count | set %up.color 0 | return 1,15 } 
  else { inc %up.color.count | set %up.color 1 | return 0,14 }
}

alias vote_test {
  set %up.color 0 | set %t.votewinner 0 | var %i = 1
  while ($gettok(%up.vote_maps,%i,32)) {
    var %t.map = $gettok(%up.vote_maps,%i,32)
    var %t.winner_amount = $gettok($eval($+(%,up.vote_votable_,$gettok(%up.vote_maps,$gettok(%t.votewinner,1,32),32)),2),0,32)
    if (!%t.winner_amount) set %t.winner_amount 0
    var %t.mapvotes = $gettok($eval($+(%,up.vote_votable_,%t.map),2),0,32)
    if (%t.mapvotes == %t.winner_amount) set %t.votewinner %t.votewinner %i
    if (%t.mapvotes > %t.winner_amount) set %t.votewinner %i
    var %t.voteshow = %t.voteshow * $+($gettok(%up.vote_maps,%i,32),:) $iif(%t.mapvotes,$ifmatch,0)
    inc %i
  }
  var %i = 1
  set %up.color.count 1
  while ($gettok(%t.voteshow,%i,42)) {
    var %t.voteshow_result = %t.voteshow_result $switch_color $gettok(%t.voteshow,%i,42)
    inc %i
  }
  if ($prop == echo)  return %t.voteshow_result 

  if ($gettok(%t.votewinner,0,32) > 1) set %vote.winner $gettok(%up.vote_maps,$gettok(%t.votewinner,$r(1,$gettok(%t.votewinner,0,32)),32),32)
  else set %vote.winner $gettok(%up.vote_maps,%t.votewinner,32)
  if (!%t.votewinner) set %vote.winner $gettok(%up.vote_maps,$r(1,$gettok(%up.vote_maps,0,32)),32)
  return %vote.winner
}


alias start_game {
  set %up.full 0
  set %up.password $+($r(a,z),$r(0,9),$r(a,z),$r(a,z),$r(0,9))
  set %up.map $vote_test
  setup_server
  var %y = $null | var %i = 1 | while ($nick($1,%i,v)) { var %y = %y $ifmatch | inc %i } 
  set %up.last_players %y
  set %up.gameover 0
  set %up.captains $gettok(%y,$r(1,$round($calc( %up.max / 2 ),0)),32) $gettok(%y,$r($calc( $round($calc(%up.max / 2),0) +1 ),%up.max),32)

  inc %pickup | .enable #busys | .disable #free
  .timerRESETP -o 1 1500 { normalize }

  .timer 1 1 ps Pickup game number %pickup is starting now!
  .timer 1 2 ps Players: %y
  .timer 1 3 ps Captains (random): %up.captains
  .timer 1 4 ps Map: %up.map
  .timer 1 5 ps Server address and password will be send to you in a private message.
  .timer 1 6 private_message %y
  .timer 1 60 devoiceall $1

  reset_votes
  halt
}

alias devoiceall {
  var %y = $null | var %i = 1 | while ($nick($1,%i,v)) { var %y = %y $ifmatch | inc %i } 
  mode $1 -vvvvvv $gettok(%y,1-6,32)
  mode $1 -vvvvv $gettok(%y,7-,32)
}

; "/ps this is a test" - pickup say.
alias ps msg %up.chan $+(,$1-,)

alias setup_server {
  .timer 1 0 q3rconsettings $gettok(%up.server,1,58) $gettok(%up.server,2,58) %up.server.rcon
  .timer 1 1 q3rcon set g_password %up.password
  .timer 1 2 q3rcon map %up.map
}

alias server_settings {
  set %up.server.rcon $2
  set %up.server $1
  q3rconsettings $gettok(%up.server,1,58) $gettok(%up.server,2,58) %up.server.rcon
}


;
; Q3 RCON for MIRC v1.00
; written by >V<Callista
; callista@void-jumper.de
;
; Feel free to redistribute, modify, copy and the rest.
; But if you do: please give me credit. Thanx.
; For comments, feedback, bug reports contact me.
;
; Have fun :)
;

alias q3rcon_binstr {
  var %i
  unset %str
  %i = 1
  %nextSpace = 0
  while (%i <= $bvar(&bin,0)) {
    if ($bvar(&bin, %i) == 32) %str = %str $+ $chr(160)
    else %str = %str $+ $chr($bvar(&bin, %i))
    inc %i
  }
}

alias q3rcon_udpread {
  sockread &temp
  if ($sockbr == 0) return
  if ($bvar(&temp,1,1) != 255) {
    echo -a 9*1q3rcon9*1 Received invalid server response.
    return
  }
  %q3pos = $bfind(&temp, 1, 10)
  %q3oldpos = %q3pos
  inc %q3oldpos
  %q3done = 1
  while (%q3done != 0) {
    %q3pos = $bfind(&temp, %q3oldpos, 10)
    if (%q3pos >= $bvar(&temp,0)) {
      %q3done = 0
    }
    bunset &bin
    bcopy &bin 1 &temp %q3oldpos $calc(%q3pos - %q3oldpos)
    q3rcon_binstr
    echo -a 9*1q3rcon9*1 9<--1 %str
    %q3oldpos = %q3pos
    inc %q3oldpos
  }
}

alias q3rconsettings {
  if ($3 == $null) {
    echo -a 9*1q3rcon9*1 You must provide three parameters: the IP, the portnumber and the password.
    return
  }
  %q3rcon_ip = $1
  %q3rcon_port = $2
  %q3rcon_password = $3
  echo -a 9*1q3rcon9*1 Settings updated.
  sockclose q3rconsock
  %q3rcon_sockopen=0
  echo -a 9*1q3rcon9*1 %q3rcon_ip

}

alias q3rcon {
  if (%q3rcon_ip == $null) {
    echo -a 9*1q3rcon9*1 You must use /q3rconsettings first.
    return
  }
  if ($1 == $null) {
    echo -a 9*1q3rcon9*1 Q3Rcon script by >V<Callista - callista@void-jumper.de
    echo -a 9*1q3rcon9*1 Use the following command first: /q3rconsettings <server ip> <server port> <rcon password>
    echo -a 9*1q3rcon9*1 Now you can send commands to this server: /q3rcon <command>
    echo -a 9*1q3rcon9*1 Example: /q3rcon serverinfo
    return
  }
  echo -a 9*1q3rcon9*1 9-->1 $1-
  bunset &bin
  bset &bin 1 255 255 255 255 $asc(r) $asc(c) $asc(o) $asc(n) 32
  %pos = 10
  %i = 1
  while (%i <= $len(%q3rcon_password)) {
    bset &bin %pos $asc($mid(%q3rcon_password,%i,1))
    inc %pos
    inc %i
  }
  bset &bin %pos 32
  inc %pos
  %i = 1
  while (%i <= $len($1-)) {
    bset &bin %pos $asc($mid($1-,%i,1))
    inc %pos
    inc %i
  }
  if (%q3rcon_sockopen != 1) {
    sockudp -k q3rconsock %q3rcon_ip %q3rcon_port &bin
    %q3rcon_sockopen=1
  }
  else sockudp -k q3rconsock %q3rcon_ip %q3rcon_port &bin
}

on 1:udpread:q3rconsock:q3rcon_udpread
