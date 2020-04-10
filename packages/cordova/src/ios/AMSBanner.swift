class AMSBanner: AMSAdBase, GADBannerViewDelegate {
    var bannerView: GADBannerView!
    var adSize: GADAdSize!
    var position: String!
    var constraintsToHide: [NSLayoutConstraint]!
    var overLap: Bool!

    var view: UIView {
        return self.plugin.viewController.view
    }

    init(id: Int, adUnitID: String, adSize: GADAdSize, position: String, overLap: Bool) {
        super.init(id: id, adUnitID: adUnitID)

        self.adSize = adSize
        self.position = position
        self.overLap = overLap
        self.constraintsToHide = [
            self.plugin.webView.topAnchor.constraint(equalTo: view.topAnchor),
            self.plugin.webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
    }

    deinit {
        bannerView = nil
    }

    func show(request: GADRequest, position: String ) {
        NSLayoutConstraint.deactivate(self.constraintsToHide)
        if bannerView != nil {
            bannerView.isHidden = false
        } else {
            bannerView = GADBannerView(adSize: self.adSize)
            addBannerViewToView(bannerView, position: position )
            bannerView.rootViewController = plugin.viewController
        }
        bannerView.delegate = self

        bannerView.adUnitID = adUnitID
        bannerView.load(request)
    }

    func hide() {
        if (bannerView?.superview) != nil {
            bannerView.delegate = nil
            bannerView.rootViewController = nil
            bannerView.removeFromSuperview()
            bannerView = nil
            NSLayoutConstraint.activate(self.constraintsToHide)
        }
    }

    func addBannerViewToView(_ bannerView: UIView, position: String ) {
        self.plugin.webView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        if #available(iOS 11.0, *) {
            positionBannerInSafeArea(bannerView, position: position )

            let background = UIView()
            background.translatesAutoresizingMaskIntoConstraints = false
            background.backgroundColor = UIColor.black
            view.addSubview(background)
            view.sendSubview(toBack: background)
            NSLayoutConstraint.activate([
                background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                background.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                background.topAnchor.constraint(equalTo: bannerView.topAnchor)
            ])

        } else {
            positionBanner(bannerView)
        }
    }

    @available (iOS 11, *)
    func positionBannerInSafeArea(_ bannerView: UIView, position: String ) {
        let guide: UILayoutGuide = view.safeAreaLayoutGuide
        var constraints = [
            bannerView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            self.plugin.webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.plugin.webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]


        if position == "top" {

            var topAnchor = bannerView.bottomAnchor
            if overLap {
                topAnchor = guide.topAnchor
            }

            constraints += [
                bannerView.topAnchor.constraint(equalTo: guide.topAnchor),
                self.plugin.webView.topAnchor.constraint(equalTo: topAnchor), //bannerView.bottomAnchor),
                self.plugin.webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]

        } else {

            var bottomAnchor = bannerView.topAnchor
            if overLap {
                bottomAnchor = guide.bottomAnchor
            }

            constraints += [
                bannerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
                self.plugin.webView.topAnchor.constraint(equalTo: view.topAnchor),
                self.plugin.webView.bottomAnchor.constraint(equalTo: bottomAnchor) // bannerView.topAnchor)
            ]

        }


        NSLayoutConstraint.activate(constraints)
    }

    func positionBanner(_ bannerView: UIView) {
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        if position == "top" {
            view.addConstraint(NSLayoutConstraint(item: bannerView,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: plugin.webView.safeAreaLayoutGuide.topAnchor ,
                                                  attribute: .top,
                                                  multiplier: 1,
                                                  constant: 0))
        } else {
            view.addConstraint(NSLayoutConstraint(item: bannerView,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: plugin.webView.safeAreaLayoutGuide.bottomAnchor,
                                                  attribute: .top,
                                                  multiplier: 1,
                                                  constant: 0))
        }
    }

    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        plugin.emit(eventType: AMSEvents.bannerLoad)
    }

    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        plugin.emit(eventType: AMSEvents.bannerLoadFail)
    }

    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        plugin.emit(eventType: AMSEvents.bannerOpen)
    }

    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
    }

    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        plugin.emit(eventType: AMSEvents.bannerClose)
    }

    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        plugin.emit(eventType: AMSEvents.bannerExitApp)
    }
}
