package com.kaltura.kdpfl.model
{
	import com.kaltura.KalturaClient;
	import com.kaltura.kdpfl.model.strings.MessageStrings;
	import com.kaltura.kdpfl.model.type.NotificationType;
	import com.kaltura.kdpfl.model.type.SourceType;
	import com.kaltura.kdpfl.model.type.StreamerType;
	import com.kaltura.kdpfl.model.vo.MediaVO;
	import com.kaltura.kdpfl.util.KTextParser;
	import com.kaltura.kdpfl.util.URLUtils;
	import com.kaltura.osmf.buffering.DualThresholdBufferingProxyElement;
	import com.kaltura.osmf.events.KSwitchingProxyEvent;
	import com.kaltura.osmf.events.KSwitchingProxySwitchContext;
	import com.kaltura.osmf.image.TimedImageElement;
	import com.kaltura.osmf.kaltura.KalturaBaseEntryResource;
	import com.kaltura.osmf.proxy.KSwitchingProxyElement;
	import com.kaltura.types.KalturaMediaType;
	import com.kaltura.vo.KalturaLiveStreamEntry;
	import com.kaltura.vo.KalturaMediaEntry;
	import com.kaltura.vo.KalturaMixEntry;
	
	import mx.utils.Base64Encoder;
	
	import org.osmf.elements.F4MElement;
	import org.osmf.elements.F4MLoader;
	import org.osmf.elements.ImageElement;
	import org.osmf.elements.ImageLoader;
	import org.osmf.elements.ProxyElement;
	import org.osmf.elements.VideoElement;
	import org.osmf.events.MediaErrorEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.URLResource;
	import org.osmf.net.DynamicStreamingItem;
	import org.osmf.net.DynamicStreamingResource;
	import org.osmf.net.NetStreamCodes;
	import org.osmf.net.StreamType;
	import org.osmf.net.StreamingURLResource;
	import org.puremvc.as3.patterns.proxy.Proxy;
	
	/**
	 * This class is the proxy for the media playing in the media player.
	 * 
	 */	
	public class MediaProxy extends Proxy
	{
		public static const NAME:String = "mediaProxy";
		public var shouldCreateSwitchingProxy : Boolean = true;
		
		private var _sendMediaReady : Boolean;
		private var _flashvars : Object;
		private var _client : KalturaClient;
		private var _isElementLoaded : Boolean;
		
		/**
		 *Constructor 
		 * @param data - value object of the Proxy.
		 * 
		 */		
		public function MediaProxy( data:Object=null )
		{
			super( NAME, new MediaVO()  );
			_flashvars = (facade.retrieveProxy( ConfigProxy.NAME ) as ConfigProxy).vo.flashvars;
			
		}
		/**
		 * Function prepares a new media element according to the information from the kaltura MediaEntry
		 * @param seekFrom - optional parameter, passed if the video being loaded is a response to intelligent seeking.
		 * 
		 */		
		public function prepareMediaElement(seekFrom :uint = 0) : void
		{
			if (!_client)
				_client = (facade.retrieveProxy( ServicesProxy.NAME ) as ServicesProxy ).kalturaClient as KalturaClient;
			var resource:MediaResourceBase;
			vo.deliveryType = _flashvars.streamerType;
			var sourceType : String = _flashvars.sourceType;
			if(vo.entry is KalturaLiveStreamEntry || _flashvars.streamerType == StreamerType.LIVE){
				vo.deliveryType = StreamerType.LIVE;
				vo.isLive = true;
			}
			else{
				vo.isLive = false;
			}
			if (!_flashvars.mediaProtocol)
			{
				vo.mediaProtocol = (vo.deliveryType != StreamerType.LIVE) ? vo.deliveryType : StreamerType.RTMP;
			}
			else
			{
				vo.mediaProtocol = (vo.deliveryType != StreamerType.LIVE) ? _flashvars.mediaProtocol : StreamerType.RTMP;
			}
			switch (sourceType) 
			{
				case SourceType.ENTRY_ID:
					
					var protocol : String;
					if((_flashvars.httpProtocol as String).indexOf("://") != -1)
					{
						protocol = (_flashvars.httpProtocol as String).replace("://", "");
					}
					if(_flashvars.referrer && _flashvars.referrer != '')
					{
						var b64 : Base64Encoder = new Base64Encoder();
						b64.encode( _flashvars.referrer );
						_flashvars.b64Referrer = b64.toString();
					}
					
					//Media Manifest construction
					var entryManifestUrl : String;
					entryManifestUrl  = _flashvars.httpProtocol + _flashvars.host + "/p/" + _flashvars.partnerId + "/sp/" + _flashvars.subpId + "/playManifest/entryId/" + vo.entry.id + ((_flashvars.deliveryCode) ? "/deliveryCode/" + _flashvars.deliveryCode : "") + ((vo.deliveryType == StreamerType.HTTP && vo.selectedFlavorId) ? "/flavorId/" + vo.selectedFlavorId : "") + (seekFrom ? "/seekFrom/" + seekFrom*1000 : "") + "/format/" + (vo.deliveryType != StreamerType.LIVE ? vo.deliveryType : "rtmp") + "/protocol/" + (vo.mediaProtocol) + (_flashvars.cdnHost ? "/cdnHost/" + _flashvars.cdnHost : "") + (_flashvars.storageId ? "/storageId/" + _flashvars.storageId : "") + (_client.ks ? "/ks/" + _client.ks : "") + (_flashvars.uiConfId ? "/uiConfId/" + _flashvars.uiConfId : "") + (_flashvars.referrerSig ? "/referrerSig/" + _flashvars.referrerSig : "") + "/a/a.f4m" + "?"+ (_flashvars.b64Referrer ? "referrer=" + _flashvars.b64Referrer : "") ;
					
					//In case partner has defined a template for the manifest URL
					if (_flashvars.manifestTemplate && _flashvars.manifestTemplate.indexOf("{") != -1)
					{
						var currVar : String = "";
						var replacedTemplate : String =_flashvars.manifestTemplate;
						var ccVarValue : Object = new Object();
						try{
							for (var i : int =0; i < _flashvars.manifestTemplate.length; i++)
							{
								if (_flashvars.manifestTemplate.charAt(i) == "{")
								{
									currVar = currVar.concat(_flashvars.manifestTemplate.charAt(i));
								}
								else if (_flashvars.manifestTemplate.charAt(i) == "}")
								{
									currVar = currVar.concat(_flashvars.manifestTemplate.charAt(i));
									
									ccVarValue = KTextParser.evaluate(facade["bindObject"], currVar );
									replacedTemplate = replacedTemplate.replace( currVar, ccVarValue );
									
									currVar = "";
								}
								else 
								{
									if (currVar != "" )
									{
										currVar = currVar.concat( _flashvars.manifestTemplate.charAt(i) );
									}
								}
							}
							
							entryManifestUrl =  replacedTemplate;
						}
						catch(e : Error)
						{
							
						}
						
					}
					resource = new StreamingURLResource (entryManifestUrl);
					
					var f4mLoader : F4MLoader = new F4MLoader(vo.mediaFactory);
					
					var f4mElem : F4MElement = new F4MElement (resource as URLResource, f4mLoader) ;
					
					var adaptedElement : DualThresholdBufferingProxyElement = new DualThresholdBufferingProxyElement((vo.deliveryType == StreamerType.LIVE ? vo.initialLiveBufferTime : vo.initialBufferTime), (vo.deliveryType == StreamerType.LIVE ? vo.expandedLiveBufferTime : vo.expandedBufferTime), f4mElem);
					vo.media = adaptedElement;
					
					
					//When using a mix entry the load is still done using flvclipper
					if (vo.entry is KalturaMixEntry)
					{
						resource = new URLResource(vo.entry.dataUrl);
						vo.media = vo.mediaFactory.createMediaElement(new KalturaBaseEntryResource( vo.entry ));
					}	
					
					//when loading a media entry we still use the flvclipper
					if((vo.entry is KalturaMediaEntry) && (vo.entry as KalturaMediaEntry).mediaType == KalturaMediaType.IMAGE)
					{
						resource = new URLResource( vo.entry.thumbnailUrl+"/width/" + vo.entry.width + "/height/"+vo.entry.height+"/.a.jpg"  );
						if(vo.supportImageDuration)
						{
							///We load the vo.entry.downloadUrl as service and append ".a.jpg" to it in order to comply with
							// the OSMF need for an extensioned url. We assume every uploaded pic will be converted to a JPG file.
							var imgDuration:Number;
							if(_flashvars.imageDefaultDuration)
								imgDuration=Number(_flashvars.imageDefaultDuration);
							else
								imgDuration=vo.imageDefaultDuration;
							
							var timedImageElement: TimedImageElement = new TimedImageElement(new ImageLoader(),new URLResource(vo.entry.thumbnailUrl+"/width/" + vo.entry.width + "/height/"+vo.entry.height+"/.a.jpg"),imgDuration);
							vo.media = timedImageElement; 
						}
						else
						{
							var imageElement : ImageElement = new ImageElement(new URLResource(vo.entry.thumbnailUrl+"/width/" + vo.entry.width + "/height/"+vo.entry.height+"/.a.jpg"), new ImageLoader());
							vo.media = imageElement;	
						} 
					}
					
					break;
				case SourceType.URL:
					switch (vo.deliveryType)
					{
						case StreamerType.LIVE:
							
							//Create resource for live streaming entry
							var liveStreamUrl : String = vo.entry.dataUrl;
							resource = new StreamingURLResource(liveStreamUrl, StreamType.LIVE);
							
							break;
						case StreamerType.RTMP:
							
							var streamFormat : String = _flashvars.streamFormat ? (_flashvars.streamFormat + ":") : "";
							var rtmpUrl:String = vo.entry.dataUrl;
							if (!URLUtils.getProtocol(rtmpUrl)) // if we didn't get a full url, we build it
							{
								rtmpUrl = _flashvars.streamerUrl + "/" + streamFormat + rtmpUrl;
							}
							if (_flashvars.rtmpFlavors)
							{
								resource = new DynamicStreamingResource(rtmpUrl,StreamType.RECORDED);
							}
							else
							{
								resource = new StreamingURLResource(rtmpUrl,StreamType.RECORDED);
							}
							
							break;
						case StreamerType.HTTP:
							var resourceUrl : String = vo.entry.dataUrl;
							resource = new URLResource( resourceUrl );
							
							break;
					}
					var elem:MediaElement = vo.mediaFactory.createMediaElement(resource);
					if (elem is VideoElement) {
						(elem as VideoElement).smoothing = true;
					}
					vo.media = new DualThresholdBufferingProxyElement(vo.deliveryType == StreamerType.LIVE ? vo.initialLiveBufferTime :vo.initialBufferTime,vo.deliveryType == StreamerType.LIVE ? vo.expandedLiveBufferTime : vo.expandedBufferTime, elem);	
					break;
				case SourceType.F4M:
					var manifestUrl : String  = vo.entry.dataUrl;
					resource = new StreamingURLResource(manifestUrl);
					
					var f4mElement : F4MElement = new F4MElement (resource as URLResource, new F4MLoader(vo.mediaFactory));
					var dtbpElement : DualThresholdBufferingProxyElement = new DualThresholdBufferingProxyElement((vo.deliveryType == StreamerType.LIVE ? vo.initialLiveBufferTime : vo.initialBufferTime), (vo.deliveryType == StreamerType.LIVE ? vo.expandedLiveBufferTime : vo.expandedBufferTime), f4mElement);
					vo.media = dtbpElement;
					break;
			}
			
			vo.resource = resource;
			
			if (shouldCreateSwitchingProxy)
			{
				var switchingMediaElement : KSwitchingProxyElement = new KSwitchingProxyElement();
				switchingMediaElement.mainMediaElement = vo.media;
				vo.media = switchingMediaElement;
				vo.media.addEventListener(KSwitchingProxyEvent.ELEMENT_SWITCH_PERFORMED, onSwitchPerformed );
				
			}
			//if the entry was empty, do nothing..
			if(!vo.media) return;
			//else..
			
		}
		/**
		 * Getter for the MediaProxy data.
		 * @return returns the MediaVO of the MediaProxy.
		 * 
		 */		
		public function get vo():MediaVO  
		{  
			return data as MediaVO;  
		} 
		/**
		 * Setter for the proxy data.
		 * @param mediaVO new data to place in the MediaVO.
		 * 
		 */        
		public function set vo (mediaVO : MediaVO) : void
		{
			data = mediaVO;
		}
		/**
		 * Getter for the VideoElement of the media.
		 * @return VideoElement
		 * 
		 */        
		public function get videoElement () : VideoElement
		{
			var media : MediaElement = vo.media;
			
			while (media is ProxyElement)
			{
				media = (media as ProxyElement).proxiedElement;
			} 
			//In order to enable Intelligent Seeking in the video, we need to receive the key-frame array from the MetaData.
			if(media is VideoElement)
			{
				return media as VideoElement;
			}
			return null;
		}
		/**
		 * Function initiates the load of the video file that belongs to the Media Element,
		 * and indicates that a MEDIA_READY notification should be sent when the process is complete.
		 * 
		 */        
		public function loadWithMediaReady () : void
		{
			_isElementLoaded = false;
			vo.media.addEventListener(MediaErrorEvent.MEDIA_ERROR, onError)
			_sendMediaReady = true;

			sendNotification(NotificationType.SOURCE_READY);

		}

		/**
		 * Function initates the load of the video file that belongs to the Media Element 
		 * and indicates that there is no need to send the MEDIA_READY notification when the process is complete.
		 * @param doPlay - flag signifying whether the video should begin playing on being loaded.
		 * 
		 */        
		public function loadWithoutMediaReady (doPlay : Boolean = false) : void
		{
			_isElementLoaded = false;
			vo.media.addEventListener(MediaErrorEvent.MEDIA_ERROR, onError)
			vo.playOnLoad = doPlay;
			_sendMediaReady = false;
			sendNotification(NotificationType.SOURCE_READY);
		}
		/**
		 * Function that handles the complete load of the video file that belongs to the media element.
		 * 
		 */        
		public function loadComplete() : void
		{
			if(!_isElementLoaded)
			{
				
				_isElementLoaded = true;
				if (videoElement)
				{
					videoElement.smoothing = true;
					videoElement.client.addHandler(NetStreamCodes.ON_META_DATA, onMetadata);
				}
				if (_sendMediaReady)
				{
					sendNotification(NotificationType.MEDIA_LOADED);	
				}
				else
				{
					if (vo.playOnLoad)
					{
						vo.playOnLoad = false;
						sendNotification(NotificationType.DO_PLAY);
					}
				}
			}
		}
		
		/**
		 * Function stores the array of key frames from the media meta data on the MediaVO.
		 * @param info the Meta Data for the kaltura media.
		 * 
		 */       
		private function onMetadata(info:Object):void// reads metadata..
		{
			vo.keyframeValuesArray=info.times; 
		}
		
		/**
		 * 
		 * @param evt
		 * 
		 */	   
		private function onError(evt:MediaErrorEvent):void
		{
			//trace("error :"+evt.error.errorCode)// TO DO: Listen this for live stream errors
			if(evt.type==MediaErrorEvent.MEDIA_ERROR)
			{
				sendNotification(NotificationType.MEDIA_ERROR);
				sendNotification(NotificationType.DO_STOP);
				sendNotification(NotificationType.ALERT,{message:MessageStrings.getString('CLIP_NOT_FOUND'),title:MessageStrings.getString('CLIP_NOT_FOUND_TITLE')})
			}
		}
		
		protected function onSwitchPerformed (e : KSwitchingProxyEvent) : void
		{
			var sequenceProxy : SequenceProxy = facade.retrieveProxy(SequenceProxy.NAME) as SequenceProxy;
			
			if (e.switchingProxySwitchContext == KSwitchingProxySwitchContext.SECONDARY)
			{
				sequenceProxy.vo.isInSequence = true;
				sequenceProxy.vo.isAdSkip = true;
			}
			else
			{
				sequenceProxy.vo.isInSequence = false;
				sequenceProxy.vo.isAdSkip = false;
			}
		}
		
		/**
		 * Finds the stream with the closest propName to the passed prefPropValue
		 * @param prefPropValue the prefered value of the prop by which to search for a stream
		 * @param propName The name of the property that the streamItems are sorted by. If no value is passed, the default is bitrate.
		 * @return the DynamicStreamingItem index. if a matching stream wasnt found return -1 (auto)
		 * 
		 */
		public function findDynamicStreamIndexByProp(prefPropValue : int , propName : String="bitrate") : int
		{
			var foundStreamIndex:int = -1;
			var foundStreamPropValue:int = -1;
			
			if (vo.resource is DynamicStreamingResource)
			{
				var streams:Vector.<DynamicStreamingItem> = (vo.resource as DynamicStreamingResource).streamItems; 
				for(var i:int = 0; i < streams.length; i++)
				{
					var h:Number = streams[i][propName];
					h = Math.round(h/100) * 100;
					if (h == prefPropValue)
					{
						foundStreamPropValue = h;
						foundStreamIndex = i;
					}
				}
				
				// if a stream was found set it as the new prefered height 				
				vo.preferedFlavorBR = foundStreamPropValue;
			}
			
			return foundStreamIndex;
		}
		
	}
}