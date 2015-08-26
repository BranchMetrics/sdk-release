package com.tune.crosspromo;

class TuneAdViewSet {
    public String placement;
    public TuneAdView view1;
    public TuneAdView view2;
    public boolean showView1;
    
    public TuneAdViewSet(String placement, TuneAdView view1, TuneAdView view2) {
        this.placement = placement;
        this.view1 = view1;
        this.view2 = view2;
        showView1 = true;
    }
    
    protected void changeView() {
        showView1 = !showView1;
    }
    
    protected TuneAdView getCurrentView() {
        if (showView1) {
            return view1;
        } else {
            return view2;
        }
    }
    
    protected TuneAdView getPreviousView() {
        if (showView1) {
            return view2;
        } else {
            return view1;
        }
    }
    
    protected void destroy() {
        view1.destroy();
        view2.destroy();
    }
}
