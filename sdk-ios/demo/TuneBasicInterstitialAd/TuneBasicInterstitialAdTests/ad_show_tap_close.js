
var target = UIATarget.localTarget();

// tap the show ad button
target.frontMostApp().mainWindow().buttons()["Show Interstitial Ad"].tap();

// tap the ad body
target.frontMostApp().mainWindow().scrollViews()[1].webViews()[0].links()[0].tap();

// tap the ad close button
target.frontMostApp().mainWindow().buttons()[0].tap();