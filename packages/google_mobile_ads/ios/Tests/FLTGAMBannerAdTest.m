// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "../Classes/FLTAdInstanceManager_Internal.h"
#import "../Classes/FLTAd_Internal.h"
#import "../Classes/FLTGoogleMobileAdsCollection_Internal.h"
#import "../Classes/FLTGoogleMobileAdsPlugin.h"
#import "../Classes/FLTGoogleMobileAdsReaderWriter_Internal.h"
#import "../Classes/FLTMobileAds_Internal.h"

@interface FLTGAMBannerAdTest : XCTestCase
@end

@implementation FLTGAMBannerAdTest {
  FLTAdInstanceManager *mockManager;
}

- (void)setUp {
  mockManager = (OCMClassMock([FLTAdInstanceManager class]));
}


- (void)testDelegates {
  FLTGAMAdRequest *request = [[FLTGAMAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  UIViewController *mockRootViewController = OCMClassMock([UIViewController class]);
  FLTGAMBannerAd *bannerAd =
      [[FLTGAMBannerAd alloc] initWithAdUnitId:@"testId"
                                         sizes:@[ [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)] ]
                                    request:[[FLTGAMAdRequest alloc] init]
                         rootViewController:mockRootViewController];
  bannerAd.manager = mockManager;
  
  [bannerAd load];
  GAMBannerView *adView = (GAMBannerView *)bannerAd.bannerView;
  XCTAssertEqual(adView.appEventDelegate, bannerAd);
  XCTAssertEqual(adView.delegate, bannerAd);
  
  [bannerAd.bannerView.delegate bannerViewDidReceiveAd:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onAdLoaded:[OCMArg isEqual:bannerAd]]);
  
  [bannerAd.bannerView.delegate bannerViewDidDismissScreen:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onBannerDidDismissScreen:[OCMArg isEqual:bannerAd]]);

  [bannerAd.bannerView.delegate bannerViewWillDismissScreen:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onBannerWillDismissScreen:[OCMArg isEqual:bannerAd]]);
  
  [bannerAd.bannerView.delegate bannerViewWillPresentScreen:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onBannerWillPresentScreen:[OCMArg isEqual:bannerAd]]);
  
  [bannerAd.bannerView.delegate bannerViewDidRecordImpression:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onBannerImpression:[OCMArg isEqual:bannerAd]]);
  
  NSString *domain = @"domain";
  NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"description" };
  NSError *error = [NSError errorWithDomain:domain code:1 userInfo:userInfo];
  [bannerAd.bannerView.delegate bannerView:OCMClassMock([GADBannerView class])
               didFailToReceiveAdWithError:error];
  OCMVerify([mockManager onAdFailedToLoad:[OCMArg isEqual:bannerAd] error:[OCMArg isEqual:error]]);
  
  [adView.appEventDelegate adView:adView didReceiveAppEvent:@"appEvent" withInfo:@"info"];
  OCMVerify([mockManager onAppEvent:[OCMArg isEqual:bannerAd]
                               name:[OCMArg isEqual:@"appEvent"]
                               data:[OCMArg isEqual:@"info"]]);

}

- (void)testLoad {
  FLTGAMAdRequest *request = [[FLTGAMAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  UIViewController *mockRootViewController = OCMClassMock([UIViewController class]);
  FLTGAMBannerAd *ad = [[FLTGAMBannerAd alloc]
        initWithAdUnitId:@"testId"
                   sizes:@[ [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)] ]
                 request:request
      rootViewController:mockRootViewController];

  XCTAssertEqual(ad.bannerView.adUnitID, @"testId");
  XCTAssertEqual(ad.bannerView.rootViewController, mockRootViewController);
  
  FLTBannerAd *mockBannerAd = OCMPartialMock(ad);
  GADBannerView *mockView = OCMClassMock([GADBannerView class]);
  OCMStub([mockBannerAd bannerView]).andReturn(mockView);
  [mockBannerAd load];

  OCMVerify([mockView loadRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
                        GADRequest *requestArg = obj;
                        return [requestArg.keywords isEqualToArray:@[ @"apple" ]];
                      }]]);
}

@end
