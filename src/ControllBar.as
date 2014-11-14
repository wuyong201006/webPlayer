package
{
	import com.ww.events.uievent.SliderBarEvent;
	import com.ww.ui.VolumeBar;
	
	import flash.display.Bitmap;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.media.SoundTransform;
	import flash.utils.setTimeout;
	
	import org.flexlite.domUI.components.Button;
	import org.flexlite.domUI.components.Group;
	import org.flexlite.domUI.components.HSlider;
	import org.flexlite.domUI.components.Rect;
	import org.flexlite.domUI.components.UIAsset;
	import org.mangui.HLS.HLS;
	import org.mangui.HLS.HLSEvent;
	import org.mangui.HLS.HLSPlayStates;
	
	import pause.png;
	
	import play.png;
	
	import zoomin.png;
	
	import zoomout.png;
	
	public class ControllBar extends Group
	{
		//M3U8解析器
		private var hlsPlayer:HLS;
		
		public function ControllBar(_hlsPlayer:HLS)
		{
			super();
			
			this.hlsPlayer = _hlsPlayer;
			
			this.hlsPlayer.addEventListener(HLSEvent.PLAYBACK_STATE,playbackChangeHandler);
			
			this.addEventListener(Event.ADDED_TO_STAGE,addToStageHandler);
		}
		
		protected function addToStageHandler(event:Event):void
		{
			stage.addEventListener(FullScreenEvent.FULL_SCREEN,fullScreenChangeHandler);
		}
		
		protected function fullScreenChangeHandler(event:FullScreenEvent):void
		{
			zoomInBtn.visible = event.fullScreen;
			zoomOutBtn.visible = ! zoomInBtn.visible;
		}
		
		//UI PlayButton
		private var playBtn:Button;
		
		//UI StopButton
		private var pauseBtn:Button;
		
		//UI ZoomIn
		private var zoomInBtn:Button;
		
		//UI ZoomOut
		private var zoomOutBtn:Button;
		
		//UI SliderBar
		private var volumeBar:HSlider;
		
		//UI Bg
		override protected function createChildren():void
		{
			super.createChildren();
			
			var bg:Rect = new Rect();
			bg.fillColor = 0x0;
			bg.alpha = 0.6;
			bg.percentHeight = bg.percentWidth = 100;
			
			addElement(bg);
			
			
			playBtn = new Button();
			playBtn.width = 20;
			playBtn.height = 23;
			playBtn.skinName = new Bitmap(new play.png());
			playBtn.horizontalCenter = 0;
			playBtn.verticalCenter = 0;
			playBtn.addEventListener(MouseEvent.CLICK,function(evt:MouseEvent):void
			{
				if(hlsPlayer)
				{
					hlsPlayer.stream.resume();
				}
			});
			
			addElement(playBtn);
			
			pauseBtn = new Button();
			pauseBtn.width = 20;
			pauseBtn.height = 23;
			pauseBtn.visible = false;
			pauseBtn.skinName = new Bitmap(new pause.png());
			pauseBtn.horizontalCenter = 0;
			pauseBtn.verticalCenter = 0;
			pauseBtn.addEventListener(MouseEvent.CLICK,function(evt:MouseEvent):void
			{
				if(hlsPlayer)
				{
					hlsPlayer.stream.pause();
				}
			});
			
			addElement(pauseBtn);
			
			zoomInBtn = new Button()
			zoomInBtn.visible = false;
			zoomInBtn.width = zoomInBtn.height = 22;
			zoomInBtn.verticalCenter = 0;
			zoomInBtn.right = 10;
			zoomInBtn.skinName = new Bitmap(new zoomin.png);
			zoomInBtn.addEventListener(MouseEvent.CLICK,zoomInOutSwitch)
			
			//addElement(zoomInBtn);

			
			zoomOutBtn = new Button()
			zoomOutBtn.verticalCenter = 0;
			zoomOutBtn.width = zoomOutBtn.height = 22;
			zoomOutBtn.right = 10;
			zoomOutBtn.skinName = new Bitmap(new zoomout.png);
			zoomOutBtn.addEventListener(MouseEvent.CLICK,zoomInOutSwitch)
			
			//addElement(zoomOutBtn);
			
			volumeBar = new HSlider();
			volumeBar.minimum = 0;
			volumeBar.maximum = 1;
			volumeBar.left = 10;
			volumeBar.stepSize = 0.1;
			volumeBar.verticalCenter = 0;
			volumeBar.addEventListener(Event.CHANGE,volumeBarChanged);
			addElement(volumeBar);
			
			setTimeout(function():void{
				volumeBar.value = 0.5;
			},50);
		}
		
		protected function volumeBarChanged(evt:Event):void
		{
			if(hlsPlayer)
			{
				var soundTransform:SoundTransform = hlsPlayer.stream.soundTransform;
				
				soundTransform.volume = volumeBar.value;
				
				hlsPlayer.stream.soundTransform = soundTransform;
				
			}
		}
		
		//PlayMediaStateChange UI State Switch
		protected function playbackChangeHandler(event:HLSEvent):void
		{
			switch(event.state)
			{
				case HLSPlayStates.IDLE:
				case HLSPlayStates.PAUSED:
				{
					playBtn.visible = true;
					pauseBtn.visible = false;
					break;
				}
				case HLSPlayStates.PAUSED_BUFFERING:
				case HLSPlayStates.PLAYING_BUFFERING:
				{
					break;
				}
					
				default:
				{
					playBtn.visible = false;
					pauseBtn.visible = true;
					break;
				}
			};
		}
		
		private function zoomInOutSwitch(evt:MouseEvent):void
		{
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}else
			{
				stage.displayState = StageDisplayState.FULL_SCREEN
			}
		}
		
		//fix 
		public function updateState():void
		{
			setTimeout(function():void{
				volumeBar.value = Math.ceil(hlsPlayer.stream.soundTransform.volume*10)/10;
			},50);
		}
		
	}
}