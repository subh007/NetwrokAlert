NetwrokAlert
============

Simple way to show ALAlert to the whole application on change of network Connectivity.

How to user it :

Include the headerfile for the Network alert and
Use the following line of code in the AppDelegate or any controller once.
```
// supply the navigation ctrl instance to the ALAlertBannerMgr
// otherwise we can't see the alert notification on the UI.
[ALAlertBannerManager sharedManager].navCtrl = self.navCtrl;
```

You have to write only once this line to your code and alert will be visible to all the controller screen.


used library:
https://github.com/alobi/ALAlertBanner 

![ScreenShot](https://dl.dropboxusercontent.com/u/32437361/connected_notif.png)
![ScreenShot](https://dl.dropboxusercontent.com/u/32437361/disconn_notif.png)
