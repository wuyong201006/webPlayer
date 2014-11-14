package
{
	import com.adobe.crypto.MD5;
	import com.alex.flexlite.components.VideoUI;
	
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.media.SoundTransform;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.Security;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.utils.Base64Encoder;
	import mx.utils.UIDUtil;
	
	import caurina.transitions.Tweener;
	
	import org.flexlite.domCore.Injector;
	import org.flexlite.domUI.components.Label;
	import org.flexlite.domUI.components.UIAsset;
	import org.flexlite.domUI.core.Theme;
	import org.flexlite.domUI.managers.SystemManager;
	import org.flexlite.domUI.skins.themes.VectorTheme;
	import org.mangui.HLS.HLS;
	import org.mangui.HLS.HLSEvent;
	import org.mangui.HLS.HLSPlayStates;
	
	public class M3U8Player extends SystemManager
	{
		
		//M3U8解析器
		private var hlsPlayer:HLS;
		
		//isdebug
		private var isdebug:Boolean = false;
		
		
		public function M3U8Player()
		{
			super();
			
			Injector.mapClass(Theme,VectorTheme);
			
			hlsPlayer = new HLS();
			
			hlsPlayer.addEventListener(HLSEvent.PLAYBACK_STATE,playbackChangeHandler);
			hlsPlayer.addEventListener(HLSEvent.MANIFEST_LOADED, manifestLoadedHandler);
			hlsPlayer.addEventListener(HLSEvent.MEDIA_TIME,mediaTimeHandler);
			hlsPlayer.addEventListener(HLSEvent.SEEK_STATE,seekStateHandler);
			
			addEventListener(Event.ADDED_TO_STAGE,addToStageHandler);
			
			//Monitor Mouse Movement
			addEventListener(MouseEvent.MOUSE_MOVE,userActiveHandler);
			
			Security.allowDomain('wechat.suntv.tv');
			
			//积分post
			urlLoader.addEventListener(Event.COMPLETE,creditPostHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
			
			//init credit parmas
			//creditParams.creditPerSec = this.loaderInfo.parameters.creditPerSec;
			creditParams.creditPerSec = 600 / 3600; //600Credits = 1h = 3600s 			
			creditParams.crediturl =  this.loaderInfo.parameters.crediturl;
			creditParams.openId = this.loaderInfo.parameters.openId;
		}
		
		protected function initCreditParams(data:Object):void
		{
			//creditParams.creditPerSec = data.creditPerSec;
			creditParams.openId = data.openId;
			creditParams.crediturl =  data.crediturl;
		}
		
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			l('IOError Credit add failure');
		}
		
		protected function creditPostHandler(event:Event):void
		{
			l('ok',urlLoader.data);
		}
		
		//seek state change
		protected function seekStateHandler(event:HLSEvent):void
		{
			l(event.state == 'SEEKING');
			
			if(event.state == 'SEEKING')
			{
				if(seeklabel) uilabel.text = seeklabel;
			}
		}
		
		//mediatime
		protected function mediaTimeHandler(event:HLSEvent):void
		{
			trace(JSON.stringify(event.mediatime));
			
			if(mediaData)
			{
				mediaData.vpos = event.mediatime.position;
				mediaData.vabs = mediaData.vstart + mediaData.vpos;
			}
		}
		
		private var _userActive:Boolean;

		public function get userActive():Boolean
		{
			return _userActive;
		}

		public function set userActive(value:Boolean):void
		{
			if(_userActive !== value)
			{
				_userActive = value;
				
				showControllBar(userActive);
			}
		}
		
		//Hide&ShowAnimation
		private function showControllBar(userActive:Boolean):void
		{
			if(controllBar)
			{
				Tweener.removeTweens(controllBar);
				
				Tweener.addTween(controllBar,{
					bottom:(userActive ? 0 : - controllBar.height ),
					time: 1
				});
			}
			
			if(topBar)
			{
				Tweener.removeTweens(topBar);
				
				Tweener.addTween(topBar,{
					top:(userActive ? 0 : - topBar.height ),
					time: 1
				});
			}
		}
		
		//DeAcitvehandlerFun
		protected function userActiveHandler(event:MouseEvent):void
		{
			userActive = true;
			
			monitorDeactive();
		}
		
		//MonitorTiemoutID
		private var monitorId:int;
		
		//Monitor Controllbar Deative
		private function monitorDeactive():void
		{
			if(monitorId) clearTimeout(monitorId);
			
			monitorId = setTimeout(function():void
			{
				userActive = false;
			},2000);
		}
		
		//M3U8ManifestFileLoaded 
		protected function manifestLoadedHandler(event:Event):void
		{
			hlsPlayer.stream.play();
		}
		
		//CreateComplete
		protected function addToStageHandler(event:Event):void
		{
			//CopyRight&Version
			Version.compileVersion(this);
			
			//AutoPlay
			videoScreen.attatchNetStream(hlsPlayer.stream);
			
			//JS2Call
			if(ExternalInterface.available)
			{
				ExternalInterface.addCallback('command',commandHandler);
			}
			
			//call2js
			if(ExternalInterface.available)
			{
				ExternalInterface.call('playerReady');
			}
			
			//initUrlParams
			if(ExternalInterface.available)
			{
				ExternalInterface.addCallback("initCredit",initCreditParams);
			}
			
			//积分处理
			stage.addEventListener(FullScreenEvent.FULL_SCREEN,fullScreenChangeHandler);
		
			//loadM3U8URL('http://stream.suntv.tvmining.com/approve/vod?channel=CCTVNEWS&startTime=1408514404&endTime=1408517914&type=iptv&test=.m3u8');
			//loadM3U8URL('http://stream.suntv.tvmining.com/approve/live?channel=CCTV1&type=iptv&suffix=m3u8&access_token=aac49710ed2e9290523db8c6c5f5fd61');
			//vod = {"buffer":65.611,"live_sliding":5.684341886080802e-14,"position":302.58099999999996,"duration":3519.9790000000003}
			
			/*
			if(isdebug)
			commandHandler({
				code:'play',
				data:{
					title:'测试',
					url:'http://stream.suntv.tvmining.com/approve/live?channel=CCTV1&type=iptv&suffix=m3u8&access_token=47f387fe86bdf8253a4f27da112e6a1a',
					extras:{
						baseLive: "http://stream.suntv.tvmining.com/approve/live",
						baseVod: "http://stream.suntv.tvmining.com/approve/vod",
						channel_name: "BTV8",
						end_time: "1408626002",
						start_time: "1408624202",
						token: "3443f9e45a9c71177b36cb91fbcf9ecf",
						view_code: "iptv"
					}
				}
			});*/
		}
		
		private function accessController():Boolean
		{
			if(isdebug) return true;
			
			if(ExternalInterface.available)
			{
				var host:String = '';

				//parent
				host = ExternalInterface.call("window.eval","document.referrer.split('/')[2]");
				
				if(host)
				{
					//l('referrer-------->',host);
				}else
				{
					host = ExternalInterface.call("window.eval",'window.location.host');
					//l('host----------->',host);
				}
				
				var hosts:Array = [
					'wxw',
					'58.215.50.188',
					'211.98.243.243',
					'suntv.tv',
					'www.suntv.tv',
					'wechat.suntv.tv',
					'tv.suntv.tv',
					'v.suntv.tv',
					'wechat.ott.cttnetcdn.com',
					'tv.10050.net',
					'tv.cibntvm.com',
					'wechat.cibntvm.com'
				];
				
				//return hosts.indexOf(host) != -1
				
				return true;
			}
			
			//comv3
			return false;
		}
		
		//command handler
		private var mediaData:Object = null;
		private function commandHandler(cdata):void
		{
			//accesscontroller
			if(! accessController())
			{
				uilabel.visible = true;
				uilabel.text = '[SORRY.该播放器只能在指定域下访问.]';
				return;
			}
			
			l(cdata);
			
			var code:String = cdata.code;
			var data:Object = cdata.data;
			
			try
			{
				switch(code)
				{
					case 'play':
							mediaData = data;
							
							if(data.hasOwnProperty('extras'))
							{
								var vstart:Number = Number(data.extras.start_time);
								var vend:Number = Number(data.extras.end_time);
								
								mediaData.islive =  vstart <= 0;
								mediaData.vstart =  mediaData.islive ? new Date().getTime()/1000 : vstart;
								mediaData.vabs = mediaData.islive ? mediaData.vstart : vstart;
								mediaData.st = vstart;
								mediaData.et = vend;
								mediaData.vod = data.extras.baseVod;
								mediaData.live = data.extras.baseLive;
								mediaData.ch = data.extras.channel_name;
								mediaData.vc = data.extras.view_code;
								mediaData.tk = data.extras.token;
							}
							
							loadM3U8URL(data.url);
					break;
					case 'playstate':
						
							//hlsPlayer.stream.togglePause();
							
							if(data.state == 'pause')
							{
								hlsPlayer.stream.pause();
							}
							if(data.state == 'play')
							{
								hlsPlayer.stream.resume();	
							}
					break;
					case 'seek':
						
						isseek = true;
						
						var offset:Number = getSeekByOffset(data.offset);
						var newOffset:Number = mediaData.vabs + offset;
						
						fasttip.visible = offset > 0;
						backtip.visible = offset < 0;
						
						if(mediaData.hasOwnProperty('extras'))
						{	
							if(mediaData.islive)
							{
								var live2vodtmp:String;
								
								var crtTime:Number = new Date().getTime()/1000;
								
								if(newOffset >= crtTime)
								{
									live2vodtmp = 'POINT?channel=CH&type=VC&access_token=TK&suffix=m3u8'.replace('POINT',mediaData.live).replace('CH',mediaData.ch).replace('VC',mediaData.vc).replace('TK',mediaData.tk);
									
									//update
									mediaData.vstart = crtTime;
								}else
								{
									live2vodtmp = 'POINT?channel=CH&startTime=ST&type=VC&access_token=TK&suffix=m3u8'.replace('POINT',mediaData.vod).replace('CH',mediaData.ch).replace('ST',newOffset).replace('VC',mediaData.vc).replace('TK',mediaData.tk);
									
									mediaData.vstart = newOffset;
								}
								
								loadM3U8URL(live2vodtmp);
								
								l('SEEK--->','islive',mediaData.islive,'now',mediaData.vabs,'offset',offset,'to',newOffset,'vstart',mediaData.vstart);
							}else
							{
								if(newOffset < mediaData.st) newOffset = mediaData.st;
								if(newOffset > mediaData.et) newOffset = mediaData.et;
								
								//update
								mediaData.vstart = newOffset;
								
								var vodtmp:String = 'POINT?channel=CH&startTime=ST&endTime=ET&type=VC&access_token=TK&suffix=m3u8'.replace('POINT',mediaData.vod).replace('CH',mediaData.ch).replace('ST',newOffset).replace('ET',mediaData.et).replace('VC',mediaData.vc).replace('TK',mediaData.tk);
								
								loadM3U8URL(vodtmp);
								
								l('SEEK--->','islive',mediaData.islive,'now',mediaData.vabs,'offset',offset,'to',newOffset,'vstart',mediaData.vstart);
							}
						}
						
					break;
					case 'volume':
							var newVol:Number = getVolumeByOffset(data.vol);
							
							var soundTransform:SoundTransform = hlsPlayer.stream.soundTransform as SoundTransform;
							soundTransform.volume += newVol;
							
							if(soundTransform.volume <= 0) soundTransform.volume = 0;
							if(soundTransform.volume >= 1) soundTransform.volume = 1;
							
							hlsPlayer.stream.soundTransform = soundTransform;
					break;
				}
				
				//激活bar
				this.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE));
				
				//bug fix
				controllBar.updateState();
			}catch(e)
			{
				l(e);
			}
		}
		
		
		//newURLOffset
		private var seeklabel:String = '';
		private function getSeekByOffset(offset:String):Number
		{
			var forward:int = offset.indexOf('-') != -1 ? -1 : 1;
			var number:int = offset.match(/\d+/)[0];
			var secondes:Number;
			
			if(offset.indexOf('m') != -1)
			{
				secondes = 60 * number;
			}
			if(offset.indexOf('h') != -1)
			{
				secondes = 60 * 60 * number;
			}
			
			seeklabel = seeklabel.replace('+','前进').replace('-','后退').replace('h','小时').replace('m','分钟');
			
			l('Seek',secondes * forward,seeklabel);
			
			return secondes * forward;
		}
		
		//newVolOffset
		private function getVolumeByOffset(offset:String):Number
		{
			l('Vol',Number(offset));
			
			return Number(offset);
		}
		
		//loadM3U8
		private function loadM3U8URL(url:String):String
		{
			try
			{
				if(url)
				{
					try{
					hlsPlayer.stream.close();}catch(e){};
					
					hlsPlayer.load(url);
					
					return 'ok';
				}
				
				return 'error';
			} 
			catch(error:Error) 
			{
				return error.message;
			}
		}
		//当前bug状态
		private var isseek:Boolean = false;
		
		//PlayMediaStateChange UI State Switch
		protected function playbackChangeHandler(event:HLSEvent):void
		{
			l('state--->',event.state);
			
			switch(event.state)
			{
				case HLSPlayStates.IDLE:
				{
					break;
				}
				case HLSPlayStates.PAUSED:
				{
					uilabel.visible = false 
					loadingTip.visible = false;
					pauseTip.visible = true;
					backtip.visible = fasttip.visible = false
					break;
				}
				case HLSPlayStates.PAUSED_BUFFERING:
				case HLSPlayStates.PLAYING_BUFFERING:
				{
					uilabel.visible = true; 
					loadingTip.visible = true;
					
					pauseTip.visible = false;
					backtip.visible = fasttip.visible = false
					
					if(mediaData)
						uilabel.text = mediaData.title;
					
					break;
				}
				default:
				{
					uilabel.visible = loadingTip.visible = pauseTip.visible = backtip.visible = fasttip.visible = false;
					isseek = true;
					break;
				}
			};
		}
		
		//UI Assets
		private var videoScreen:VideoUI;
		
		//UI Loading
		private var loadingTip:UIAsset;
		
		//UI ControllerBar
		private var controllBar:ControllBar;
		
		//UI TopBar
		private var topBar:TopBar;
		
		//UI Label
		private var uilabel:Label;
		
		//playbutton
		private var playingTip:UIAsset;
		
		//pausebutton
		private var pauseTip:UIAsset;
		
		//fastforward
		private var fasttip:UIAsset;
		
		//backforward
		private var backtip:UIAsset;
		
		
		//UI Comps
		override protected function createChildren():void
		{
			super.createChildren();
			
			videoScreen = new VideoUI();
			videoScreen.percentHeight = videoScreen.percentWidth = 100;
			
			addElement(videoScreen);
			
			
			loadingTip = new UIAsset();
			loadingTip.visible = false;
			loadingTip.scaleX = loadingTip.scaleY = 11/20;
			loadingTip.horizontalCenter = 0;
			loadingTip.verticalCenter = 0;
			loadingTip.skinName = Loading_b;
			
			addElement(loadingTip);
			
			playingTip = new UIAsset();
			playingTip.visible = false;
			playingTip.buttonMode = true;
			playingTip.scaleX = playingTip.scaleY = 11/20;
			playingTip.horizontalCenter = 0;
			playingTip.verticalCenter = 0;
			playingTip.skinName = PlayButton_b;
			playingTip.addEventListener(MouseEvent.CLICK,playMediaHanlder);
			
			addElement(playingTip);
			
			pauseTip = new UIAsset();
			pauseTip.visible = false;
			pauseTip.buttonMode = true;
			pauseTip.horizontalCenter = 0;
			pauseTip.scaleX = pauseTip.scaleY = 11/20;
			pauseTip.verticalCenter = 0;
			pauseTip.skinName = PauseButton_b;
			pauseTip.addEventListener(MouseEvent.CLICK,playMediaHanlder);
			
			
			addElement(pauseTip);
			
			
			fasttip = new UIAsset();
			fasttip.scaleX = fasttip.scaleY = 11/20;
			fasttip.visible = false;
			fasttip.buttonMode = true;
			fasttip.horizontalCenter = 0;
			fasttip.verticalCenter = 0;
			fasttip.skinName = FastwardButton_a;
			
			
			addElement(fasttip);
			
			
			backtip = new UIAsset();
			backtip.scaleX = backtip.scaleY = 11/20;
			backtip.visible = false;
			backtip.buttonMode = true;
			backtip.horizontalCenter = 0;
			backtip.verticalCenter = 0;
			backtip.skinName = BackwardButton_a;
			
			
			addElement(backtip);
			
			uilabel = new Label();
			uilabel.visible = false;
			uilabel.textColor = 0xcccccc;
			uilabel.size = 24;
//			uilabel.bold = true;
			uilabel.text = '正在加载中';
			uilabel.horizontalCenter = 0;
			uilabel.verticalCenter = 60 * 1.5;
			addElement(uilabel);
			
			controllBar = new ControllBar(hlsPlayer);
			controllBar.percentWidth = 100;
			controllBar.height = 40;
			controllBar.bottom = - controllBar.height;
			
			addElement(controllBar);
			
			
			topBar = new TopBar(hlsPlayer);
			topBar.percentWidth = 100;
			topBar.height = 40;
			topBar.top = - topBar.height;
			
			addElement(topBar);
		}
		
		//播放流
		protected function playMediaHanlder(event:MouseEvent):void
		{
			hlsPlayer.stream.resume();

			//bug fix
			playingTip.visible = false;
		}
		
		private function l(...args):void
		{
			var logstr:String = JSON.stringify(args);
			
			trace('LOCAL LOG:-->',logstr);
			
			if(ExternalInterface.available)
			{
				ExternalInterface.call('console.log','M3U8PLAYER--->',logstr);
			}
		}
		
		protected function fullScreenChangeHandler(event:FullScreenEvent):void
		{
			if(creditParams.hasOwnProperty('openId') && creditParams.hasOwnProperty('crediturl'))
			{
				if(event.fullScreen)
				{
					startClock();
				}else
				{
					//积分处理
					stopClock();
					
					//积分处理
					postCredit();
				}
			}
		}
		
		private var timer:Timer = new Timer(1000);
		private var timeStart:Number;
		
		protected function startClock():void
		{
			if(!timer.running)
			{
				timer.reset();
				timer.start();
			}
		}
		
		protected function stopClock():void
		{
			if(timer.running)
			{
				timer.stop();
			}
		}
		
		private function number2Asc2 (number):String
		{
			var asc2:String = '';
			
			var nums:Array = (number + '').split ('');
			
			nums.forEach(function(per:String,index:int,arr:Array):void{
				asc2 += String.fromCharCode (60 + parseInt (per));
			});
			
			return asc2;
		}
		
		//flashvars required
		/*
		crediturl
		creditPerSec
		openId
		*/
		private var creditParams:Object = {
			creditPerSec: null,
			crediturl: null,
			openId: null
		};
		private var urlReq:URLRequest = new URLRequest();
		private var urlLoader:URLLoader = new URLLoader();
		private var baseEncoder:Base64Encoder = new Base64Encoder();
		protected function postCredit():void
		{
			//5s钟计时开始
			if(timer.currentCount < 5 * 60)
			{
				l('不满足加分条件[5m]');
				return;
			}
			
			/*
			l(creditParams);
			l(creditParams.creditPerSec);
			l(timer.currentCount);
			*/
			
			try
			{
				var realmin:Number = Math.floor((timer.currentCount / 60));
				
				var rdcode:String = UIDUtil.createUID();
				var credits:Number = Math.ceil(realmin * 60 * creditParams.creditPerSec);
				
				baseEncoder.encode(credits.toString() + '_' + rdcode + '_' + MD5.hash(number2Asc2(credits) + rdcode));
				
				urlReq.method = URLRequestMethod.GET;
				urlReq.url = creditParams.crediturl + 
					"?openId=" +  creditParams.openId +
					"&credit=" + baseEncoder.flush();
				
				l('观看分钟数:' , realmin,'秒数' , realmin * 60 , '每秒积分:',creditParams.creditPerSec,'积分',credits);
				try
				{
					urlLoader.load(urlReq);
				} 
				catch(error:Error) 
				{
					l(error.message);	
				}
			}
			catch(error:Error) 
			{
				l("PostCreditError",error);
			}
		}
	}
}

/* vod - extras
baseLive: "http://stream.suntv.tvmining.com/approve/live"
baseVod: "http://stream.suntv.tvmining.com/approve/vod"
channel_name: "BTV8"
end_time: "1408626002"
start_time: "1408624202"
token: "3443f9e45a9c71177b36cb91fbcf9ecf"
view_code: "iptv"
http://stream.suntv.tvmining.com/approve/vod?channel=BTV8&startTime=1408624202&endTime=1408626002&type=iptv&test=.m3u8&access_token=3443f9e45a9c71177b36cb91fbcf9ecf
*/
/*
live - extras
baseLive: "http://stream.suntv.tvmining.com/approve/live"
baseVod: "http://stream.suntv.tvmining.com/approve/vod"
channel_name: "AnHuiTV"
end_time: 0
start_time: 0
token: "b8066885a7dfb7fa3342c265ecbb9325"
view_code: "iptv"
""
*/

/*
var newurl:String;
if(data.url.indexOf('approve/live') != -1)//live
{

}else//vod
{

}

loadM3U8URL(data.extras.baseVod + '?channel='+data.extras.channel_name+'&startTime=1408624202&endTime=1408626002&type=iptv&test=.m3u8&access_token=3443f9e45a9c71177b36cb91fbcf9ecf);
*/