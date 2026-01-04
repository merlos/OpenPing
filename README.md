# Open Ping for iOS

Simple application that allows you to ping a domain or an IP (IPv4). Main use cases:

1. Check if the internet is down
2. Check if a host is up
3. Check if a hosit in another subnet can be reached (f.i. within a VPN)

![video](./media/1.0.0/iphone-video.gif)


## Install / Download

**[Available on the App Store](https://apps.apple.com/us/app/open-ping-network-icmp-tool/id6740431290)**




## why did you create Open Ping?
During a lot of time I used [Mocha Ping Lite](https://mochasoft.dk/iphone_ping.htm) which was fine and free. I only used the ping a single IP, and I usually pinged a few IPs or domains... but main problem was accessing the history. 

Most of the time I just wanted to ping some domain or IP that I already pinged in the past, I wanted to tap on the domain. So, one day I did some research on existing libraries, et voilá. 

## Acknoledgements

The code that performs the actual ping is based on https://github.com/samiyr/SwiftyPing/ (MIT license)

## LICENSE

GPLv3

(except for the [SwiftyPing](/Open%20Ping/SwiftyPing.swift) which is MIT)
