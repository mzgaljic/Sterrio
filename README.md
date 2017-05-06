<img src="https://dl.dropbox.com/s/vhqjrunicc8ze2p/readme%20image.png" width="1425">

#### Screenshots
<img src="https://dl.dropbox.com/s/j7yvr3etjz350ni/1.png" width="215"> <img src="https://dl.dropbox.com/s/44wucerrml3e53x/2.png" width="215"> <img src="https://dl.dropbox.com/s/uqv0jqlox3n2xnq/3.png" width="215"> <img src="https://dl.dropbox.com/s/nt15grcvwt7es0z/4.png" width="215">

**Key features**:
- Intelligent song meta-data tagging. (powered by Discogs API)
- Listen to songs while Sterrio is in the background.
- Easily organize music videos and create playlists.
- Sophisticated queue playback, repeat & shuffle modes.
- iCloud sync, AirPlay, library search and more...

#### App requirements & project history
Sterrio was last updated in late 2016 and tested on iOS 8, 9 and 10. Sterrio looks best on iPhone because autolayout was not a priority when learning iOS back in 2014.

Sterrio was a side project I started in May 2014 because I wanted to learn mobile development. I ended up growing very passionate about it and finally released it on the App Store in 2016 after spending thousands of hours on the project. Many tough lessons were learned building this project - the largest one being the value of a mimimum viable product and iterating quickly. It is also an example for why unit testing and documentation is *crucial*  for a massive project.

------------

This project does not have a single unit test. 85% of the app was complete by the time I learned how to properly unit test my code. However, Sterrio was remarkably stable during it's time on the iOS App Store considering all testing was manual. Fabric metrics indicate Approx. 90% of installs were crash free.

#### Coming soon: 
Need to make it easy for anyone to specify their own YouTube and Discogs API keys. To do so now, the following should be updated:
<br/>**YouTube API key**
`YouTubeService.m - line 73`
<br/>**Discogs API key**
` DiscogsItem.m - line 41`

##### API Keys: 
YouTube and Discogs API keys found in the repo were used in production but have since been disabled because Sterrio was taken off of the iOS App Store.
