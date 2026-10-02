package com.vermajeeverma.turborush.ads;

import android.app.Activity;
import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.IUnityAdsLoadListener;
import com.unity3d.ads.IUnityAdsShowListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.ads.UnityAdsShowOptions;
import com.unity3d.services.banners.BannerErrorInfo;
import com.unity3d.services.banners.BannerView;
import com.unity3d.services.banners.UnityBannerSize;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

@SuppressWarnings({"deprecation"})
public final class TurboUnityAdsPlugin extends GodotPlugin {

    private static final int BANNER_WIDTH = 320;
    private static final int BANNER_HEIGHT = 50;

    private volatile boolean initialized = false;
    private volatile boolean rewardedLoaded = false;
    private volatile boolean interstitialLoaded = false;

    private BannerView topBanner;
    private BannerView bottomBanner;
    private FrameLayout contentRoot;

    private String rewardedPlacement = "";
    private String interstitialPlacement = "";

    private final IUnityAdsLoadListener loadListener = new IUnityAdsLoadListener() {
        @Override
        public void onUnityAdsAdLoaded(@NonNull String placementId) {
            if (placementId.equals(rewardedPlacement)) {
                rewardedLoaded = true;
                return;
            }
            if (placementId.equals(interstitialPlacement)) {
                interstitialLoaded = true;
            }
        }

        @Override
        public void onUnityAdsFailedToLoad(@NonNull String placementId,
                                           @NonNull UnityAds.UnityAdsLoadError error,
                                           @NonNull String message) {
            if (placementId.equals(rewardedPlacement)) {
                rewardedLoaded = false;
            }
            if (placementId.equals(interstitialPlacement)) {
                interstitialLoaded = false;
            }
            emitSignal("unity_ads_error", placementId + ": " + message);
        }
    };

    public TurboUnityAdsPlugin(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "TurboUnityAds";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("unity_ads_initialized", Boolean.class));
        signals.add(new SignalInfo("unity_ads_rewarded"));
        signals.add(new SignalInfo("unity_ads_closed"));
        signals.add(new SignalInfo("unity_ads_error", String.class));
        return signals;
    }

    @UsedByGodot
    public boolean initialize(final String gameId, final boolean testMode) {
        final Activity host = getActivity();
        if (host == null || gameId == null || gameId.trim().isEmpty()) {
            emitSignal("unity_ads_error", "Missing Android Unity Ads Game ID");
            return false;
        }

        runOnHostThread(() -> {
            try {
                // Turbo Rush intentionally uses non-behavioral advertising until a full
                // publisher consent flow is configured.
                UnityAds.setNonBehavioral(true);
                UnityAds.initialize(
                        host.getApplicationContext(),
                        gameId,
                        testMode,
                        new IUnityAdsInitializationListener() {
                            @Override
                            public void onInitializationComplete() {
                                initialized = true;
                                emitSignal("unity_ads_initialized", true);
                                if (!rewardedPlacement.isEmpty()) {
                                    loadRewardedAd(rewardedPlacement);
                                }
                                if (!interstitialPlacement.isEmpty()) {
                                    loadInterstitialAd(interstitialPlacement);
                                }
                            }

                            @Override
                            public void onInitializationFailed(
                                    @NonNull UnityAds.UnityAdsInitializationError error,
                                    @NonNull String message) {
                                initialized = false;
                                emitSignal("unity_ads_initialized", false);
                                emitSignal("unity_ads_error", error.name() + ": " + message);
                            }
                        },
                        testMode
                );
            } catch (Throwable t) {
                initialized = false;
                emitSignal("unity_ads_initialized", false);
                emitSignal("unity_ads_error", String.valueOf(t.getMessage()));
            }
        });
        return true;
    }

    @UsedByGodot
    public boolean isInitialized() {
        return initialized || UnityAds.isInitialized();
    }

    @UsedByGodot
    public boolean loadInterstitialAd(final String placementId) {
        if (placementId == null || placementId.trim().isEmpty()) {
            return false;
        }
        interstitialPlacement = placementId.trim();
        interstitialLoaded = false;
        if (!isInitialized()) {
            return true;
        }
        runOnHostThread(() -> {
            try {
                UnityAds.load(interstitialPlacement, loadListener);
            } catch (Throwable t) {
                emitSignal("unity_ads_error", "Interstitial load exception: " + t.getMessage());
            }
        });
        return true;
    }

    @UsedByGodot
    public boolean loadRewardedAd(final String placementId) {
        if (placementId == null || placementId.trim().isEmpty()) {
            return false;
        }
        rewardedPlacement = placementId.trim();
        rewardedLoaded = false;
        if (!isInitialized()) {
            return true;
        }
        runOnHostThread(() -> {
            try {
                UnityAds.load(rewardedPlacement, loadListener);
            } catch (Throwable t) {
                emitSignal("unity_ads_error", "Rewarded load exception: " + t.getMessage());
            }
        });
        return true;
    }

    @UsedByGodot
    public boolean isRewardedReady() {
        return rewardedLoaded;
    }

    @UsedByGodot
    public boolean isInterstitialReady() {
        return interstitialLoaded;
    }

    @UsedByGodot
    public boolean showRewardedAd(final String placementId) {
        if (!isInitialized() || placementId == null || placementId.trim().isEmpty() || !rewardedLoaded) {
            return false;
        }
        rewardedLoaded = false;
        runOnHostThread(() -> {
            final Activity host = getActivity();
            if (host == null) {
                emitSignal("unity_ads_error", "No host Activity");
                return;
            }
            try {
                UnityAds.show(host, placementId, new UnityAdsShowOptions(), new IUnityAdsShowListener() {
                    @Override
                    public void onUnityAdsShowFailure(@NonNull String placementId,
                                                       @NonNull UnityAds.UnityAdsShowError error,
                                                       @NonNull String message) {
                        emitSignal("unity_ads_error", error.name() + ": " + message);
                        loadRewardedAd(rewardedPlacement);
                    }

                    @Override
                    public void onUnityAdsShowStart(@NonNull String placementId) {
                    }

                    @Override
                    public void onUnityAdsShowClick(@NonNull String placementId) {
                    }

                    @Override
                    public void onUnityAdsShowComplete(
                            @NonNull String placementId,
                            @NonNull UnityAds.UnityAdsShowCompletionState state) {
                        if (state == UnityAds.UnityAdsShowCompletionState.COMPLETED) {
                            emitSignal("unity_ads_rewarded");
                        }
                        emitSignal("unity_ads_closed");
                        loadRewardedAd(rewardedPlacement);
                    }
                });
            } catch (Throwable t) {
                emitSignal("unity_ads_error", "Rewarded show exception: " + t.getMessage());
                loadRewardedAd(rewardedPlacement);
            }
        });
        return true;
    }

    @UsedByGodot
    public boolean showInterstitialAd(final String placementId) {
        if (!isInitialized() || placementId == null || placementId.trim().isEmpty() || !interstitialLoaded) {
            return false;
        }
        interstitialLoaded = false;
        runOnHostThread(() -> {
            final Activity host = getActivity();
            if (host == null) {
                emitSignal("unity_ads_error", "No host Activity");
                return;
            }
            try {
                UnityAds.show(host, placementId, new UnityAdsShowOptions(), new IUnityAdsShowListener() {
                    @Override
                    public void onUnityAdsShowFailure(@NonNull String placementId,
                                                       @NonNull UnityAds.UnityAdsShowError error,
                                                       @NonNull String message) {
                        emitSignal("unity_ads_error", error.name() + ": " + message);
                        loadInterstitialAd(interstitialPlacement);
                    }

                    @Override
                    public void onUnityAdsShowStart(@NonNull String placementId) {
                    }

                    @Override
                    public void onUnityAdsShowClick(@NonNull String placementId) {
                    }

                    @Override
                    public void onUnityAdsShowComplete(
                            @NonNull String placementId,
                            @NonNull UnityAds.UnityAdsShowCompletionState state) {
                        emitSignal("unity_ads_closed");
                        loadInterstitialAd(interstitialPlacement);
                    }
                });
            } catch (Throwable t) {
                emitSignal("unity_ads_error", "Interstitial show exception: " + t.getMessage());
                loadInterstitialAd(interstitialPlacement);
            }
        });
        return true;
    }

    @UsedByGodot
    public boolean showLoadingBanners(final String topPlacementId, final String bottomPlacementId) {
        if (!isInitialized()) {
            return false;
        }
        final Activity host = getActivity();
        if (host == null) {
            return false;
        }
        final String topId = topPlacementId == null ? "" : topPlacementId.trim();
        final String bottomId = bottomPlacementId == null ? "" : bottomPlacementId.trim();
        if (topId.isEmpty() || bottomId.isEmpty()) {
            return false;
        }

        runOnHostThread(() -> {
            contentRoot = host.findViewById(android.R.id.content);
            if (contentRoot == null) {
                emitSignal("unity_ads_error", "Android content root not found");
                return;
            }

            removeBannerViews();

            topBanner = createBanner(host, topId);
            bottomBanner = createBanner(host, bottomId);

            addBanner(contentRoot, topBanner, Gravity.TOP);
            addBanner(contentRoot, bottomBanner, Gravity.BOTTOM);

            try {
                topBanner.load();
                bottomBanner.load();
            } catch (Throwable t) {
                emitSignal("unity_ads_error", "Banner load exception: " + t.getMessage());
            }
        });
        return true;
    }

    @UsedByGodot
    public void hideLoadingBanners() {
        runOnHostThread(this::removeBannerViews);
    }

    private BannerView createBanner(Activity host, String placementId) {
        BannerView view = new BannerView(host, placementId, new UnityBannerSize(BANNER_WIDTH, BANNER_HEIGHT));
        view.setListener(new BannerView.IListener() {
            @Override
            public void onBannerLoaded(BannerView bannerAdView) {
            }

            @Override
            public void onBannerFailedToLoad(BannerView bannerAdView, BannerErrorInfo errorInfo) {
                emitSignal("unity_ads_error", "Banner: " + errorInfo.toString());
            }

            @Override
            public void onBannerShown(BannerView bannerAdView) {
            }

            @Override
            public void onBannerClick(BannerView bannerAdView) {
            }

            @Override
            public void onBannerLeftApplication(BannerView bannerAdView) {
            }
        });
        view.setBackgroundColor(Color.TRANSPARENT);
        view.setVisibility(View.VISIBLE);
        return view;
    }

    private void addBanner(FrameLayout parent, BannerView view, int gravity) {
        if (view == null) {
            return;
        }
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                BANNER_WIDTH,
                BANNER_HEIGHT
        );
        params.gravity = gravity | Gravity.CENTER_HORIZONTAL;
        parent.addView(view, params);
    }

    private void removeBannerViews() {
        if (contentRoot != null) {
            if (topBanner != null) {
                contentRoot.removeView(topBanner);
            }
            if (bottomBanner != null) {
                contentRoot.removeView(bottomBanner);
            }
        }
        topBanner = null;
        bottomBanner = null;
    }
}
