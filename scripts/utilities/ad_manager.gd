extends Node

signal user_earned_reward(reward_type: String)
signal rewarded_ad_dismissed
signal rewarded_ad_failed_to_load

signal interstitial_ad_dismissed
signal interstitial_ad_failed_to_load

var rewarded_ad: RewardedAd
var rewarded_loader: RewardedAdLoader
var current_reward_type: String = ""
var _is_loading_rewarded_ad: bool = false
var _rewarded_load_callback: RewardedAdLoadCallback
var _rewarded_full_screen_callback: FullScreenContentCallback
var _rewarded_earn_listener: OnUserEarnedRewardListener

var interstitial_ad: InterstitialAd
var interstitial_loader: InterstitialAdLoader
var _is_loading_interstitial_ad: bool = false
var _interstitial_load_callback: InterstitialAdLoadCallback
var _interstitial_full_screen_callback: FullScreenContentCallback

func _ready() -> void:
	MobileAds.initialize()
	
	load_rewarded_ad()
	load_interstitial_ad()

func load_rewarded_ad() -> void:
	if rewarded_ad != null or _is_loading_rewarded_ad:
		return

	_is_loading_rewarded_ad = true
	var ad_unit_id := "ca-app-pub-3940256099942544/5224354917"
	rewarded_loader = RewardedAdLoader.new()
	_rewarded_load_callback = RewardedAdLoadCallback.new()
	
	_rewarded_load_callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		rewarded_ad = ad
		_is_loading_rewarded_ad = false
		print("Rewarded ad loaded.")
		setup_rewarded_callbacks()
		
	_rewarded_load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("Rewarded ad failed to load: ", error.message)
		_is_loading_rewarded_ad = false
		rewarded_ad_failed_to_load.emit()
		
	rewarded_loader.load(ad_unit_id, AdRequest.new(), _rewarded_load_callback)

func setup_rewarded_callbacks() -> void:
	if not rewarded_ad:
		return
	_rewarded_full_screen_callback = FullScreenContentCallback.new()
	_rewarded_full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Rewarded ad dismissed.")
		rewarded_ad.destroy()
		rewarded_ad = null
		rewarded_ad_dismissed.emit()
		call_deferred("load_rewarded_ad")
		
	_rewarded_full_screen_callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		print("Rewarded ad failed to show: ", error.message)
		rewarded_ad.destroy()
		rewarded_ad = null
		rewarded_ad_dismissed.emit()
		call_deferred("load_rewarded_ad")
		
	rewarded_ad.full_screen_content_callback = _rewarded_full_screen_callback

func show_rewarded_ad(reward_type: String) -> void:
	if not rewarded_ad:
		print("Rewarded ad not loaded. Attempting to load...")
		load_rewarded_ad()
		return
		
	current_reward_type = reward_type
	_rewarded_earn_listener = OnUserEarnedRewardListener.new()
	_rewarded_earn_listener.on_user_earned_reward = func(_rewarded_item: RewardedItem) -> void:
		print("Player rewarded! Type: ", current_reward_type)
		user_earned_reward.emit(current_reward_type)
		
	rewarded_ad.show(_rewarded_earn_listener)

func is_rewarded_ad_loaded() -> bool:
	return rewarded_ad != null

func load_interstitial_ad() -> void:
	if interstitial_ad != null or _is_loading_interstitial_ad:
		return

	_is_loading_interstitial_ad = true
	var ad_unit_id := "ca-app-pub-3940256099942544/1033173712"
	interstitial_loader = InterstitialAdLoader.new()
	_interstitial_load_callback = InterstitialAdLoadCallback.new()
	
	_interstitial_load_callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		interstitial_ad = ad
		_is_loading_interstitial_ad = false
		print("Interstitial loaded.")
		setup_interstitial_callbacks()
		
	_interstitial_load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("Interstitial failed to load: ", error.message)
		_is_loading_interstitial_ad = false
		interstitial_ad_failed_to_load.emit()
		
	interstitial_loader.load(ad_unit_id, AdRequest.new(), _interstitial_load_callback)

func setup_interstitial_callbacks() -> void:
	if not interstitial_ad:
		return
	_interstitial_full_screen_callback = FullScreenContentCallback.new()
	_interstitial_full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Interstitial dismissed.")
		interstitial_ad.destroy()
		interstitial_ad = null
		interstitial_ad_dismissed.emit()
		call_deferred("load_interstitial_ad")
		
	_interstitial_full_screen_callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		print("Interstitial failed to show: ", error.message)
		interstitial_ad.destroy()
		interstitial_ad = null
		interstitial_ad_dismissed.emit()
		call_deferred("load_interstitial_ad")
		
	interstitial_ad.full_screen_content_callback = _interstitial_full_screen_callback

func show_interstitial_ad() -> void:
	if interstitial_ad:
		interstitial_ad.show()
	else:
		print("Interstitial not loaded yet. Attempting to load...")
		load_interstitial_ad()

func is_interstitial_ad_loaded() -> bool:
	return interstitial_ad != null