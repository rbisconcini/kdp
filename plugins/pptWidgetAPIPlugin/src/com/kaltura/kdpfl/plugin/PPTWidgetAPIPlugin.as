package com.kaltura.kdpfl.plugin 
{
	import com.kaltura.vo.KalturaDataEntry;
	
	import fl.data.DataProvider;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import org.puremvc.as3.interfaces.IFacade;

	public dynamic class PPTWidgetAPIPlugin extends Sprite implements IPlugin
	{
		public var nextButtonId:DisplayObject;
		public var prevButtonId:DisplayObject;
		public var pptWidgetVersion : String="3.4.5.4"
		protected var _facade:IFacade;
		protected var _mediator:PPTWidgetAPIMediator;
		protected var _bitmapData:BitmapData;
		protected var _dataProvider:DataProvider;
		protected var _shouldSave:Boolean;
		protected var _displayPrevButton:Boolean = false;
		protected var _displayNextButton:Boolean = false;
		protected var _enablePPTControls:Boolean = false;
		protected var _adminMode:Boolean = false;
		protected var _toggleGallery : Boolean = true;
		protected var _enableAddMark : Boolean = true;
		protected var _showOnlyPPT : Boolean = true;
		protected var _showOnlyVideo : Boolean = true;
		protected var _presentationMovieClip : MovieClip;
		protected var _gallerySize : int;
		protected var _decreasedBitmapSize : Number;
		private var _dataEntry : KalturaDataEntry;
		private var _isMarkSelected : Boolean;
		
		
		public function PPTWidgetAPIPlugin()
		{
		}
		
		

		public function setSkin(styleName:String, setSkinSize:Boolean=false):void { }
		
		public function initializePlugin(facade:IFacade):void
		{
			_dataProvider = new DataProvider();
			_facade = facade;
			_mediator = new PPTWidgetAPIMediator(this);
			_facade.registerMediator(_mediator);
		}
		
		[Bindable]
		public function set bitmapDataProvider(bitmapData:BitmapData):void { _bitmapData = bitmapData; }
		public function get bitmapDataProvider():BitmapData { return _bitmapData; }
		
		[Bindable]
		public function set carouselPicturesDataProvider(v:DataProvider):void { _dataProvider = v; }
		public function get carouselPicturesDataProvider():DataProvider { return _dataProvider; }
		
		[Bindable]
		public function set shouldSave(v:Boolean):void { _shouldSave = v; }
		public function get shouldSave():Boolean { return _shouldSave; }
		
		[Bindable]
		public function set displayPrevButton(v:Boolean):void { _displayPrevButton = v; }
		public function get displayPrevButton():Boolean { return _displayPrevButton; }
		
		[Bindable]
		public function set displayNextButton(v:Boolean):void { _displayNextButton = v; }
		public function get displayNextButton():Boolean { return _displayNextButton; }
		
		[Bindable]
		public function set adminMode(v:Boolean):void { _adminMode = v; }
		public function get adminMode():Boolean { return _adminMode; }
		
		[Bindable]
		public function set enablePPTControls(enable:Boolean):void { _enablePPTControls=enable; }
		public function get enablePPTControls():Boolean { return _enablePPTControls; }
		
		[Bindable]
		public function set toggleGallery(visible : Boolean):void { _toggleGallery = visible; }
		public function get toggleGallery() : Boolean {return _toggleGallery; }

		[Bindable]
		public function get enableAddMark():Boolean {return _enableAddMark;}
		public function set enableAddMark(value:Boolean):void {_enableAddMark = value;}
		
		[Bindable]
		public function set showOnlyPPT(showPPT : Boolean):void { _showOnlyPPT = showPPT; }
		public function get showOnlyPPT() : Boolean {return _showOnlyPPT; }
		
		[Bindable]
		public function set showOnlyVideo(showPPT : Boolean):void { _showOnlyVideo = showPPT; }
		public function get showOnlyVideo() : Boolean {return _showOnlyVideo; }

		[Bindable]
		public function get dataEntry():KalturaDataEntry{ return _dataEntry; }
		public function set dataEntry(value:KalturaDataEntry):void { _dataEntry = value; }

		[Bindable]
		public function get presentationMovieClip():MovieClip { return _presentationMovieClip; }
		public function set presentationMovieClip(value:MovieClip):void { _presentationMovieClip = value; }
		
		[Bindable]
		public function get gallerySize():int
		{
			return _gallerySize;
		}

		public function set gallerySize(value:int):void
		{
			_gallerySize = value;
		}
		
		[Bindable]
		public function get decreasedBitmapSize():Number
		{
			//The reason for returning the double value is that the decreased bitmap in the gallery at the
			//bottom of the screen has a tooltip which is twice as large, therefore the quality of the decreased
			//Bitmap will be determined by the tooltip and not the thumbnail.
			return _decreasedBitmapSize*2;
		}

		public function set decreasedBitmapSize(value:Number):void
		{
			_decreasedBitmapSize = value;
		}
		
		[Bindable]
		public function get isMarkSelected():Boolean
		{
			return _isMarkSelected;
		}
		
		public function set isMarkSelected(value:Boolean):void
		{
			_isMarkSelected = value;
		}


	}
}