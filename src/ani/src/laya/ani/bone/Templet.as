package laya.ani.bone {
	import laya.ani.KeyframesAniTemplet;
	import laya.ani.bone.BoneSlot;
	import laya.ani.bone.SkinData;
	import laya.ani.bone.SkinSlotDisplayData;
	import laya.ani.bone.SlotData;
	import laya.ani.bone.Transform;
	import laya.display.Graphics;
	import laya.events.Event;
	import laya.resource.Texture;
	import laya.utils.Byte;
	
	/**数据解析完成后的调度。
	 * @eventType Event.COMPLETE
	 * */
	[Event(name = "complete", type = "laya.events.Event")]
	/**数据解析错误后的调度。
	 * @eventType Event.ERROR
	 * */
	[Event(name = "error", type = "laya.events.Event")]
	/**
	 * 动画模板类
	 */
	public class Templet extends KeyframesAniTemplet {
		
		public static var TEMPLET_DICTIONARY:Object;
		
		private var _mainTexture:Texture;
		private var _textureJson:*;
		private var _graphicsCache:Array = [];
		
		/** 存放原始骨骼信息 */
		public var srcBoneMatrixArr:Array = [];
		/** 存放插槽数据的字典 */
		public var boneSlotDic:Object = {};
		/** 绑定插槽数据的字典 */
		public var bindBoneBoneSlotDic:Object = {};
		/** 存放插糟数据的数组 */
		public var boneSlotArray:Array = [];
		/** 皮肤数据 */
		public var skinDataArray:Array = [];
		/** 皮肤的字典数据 */
		public var skinDic:Object = {};
		/** 存放纹理数据 */
		public var subTextureDic:Object = {};
		/** 是否解析失败 */
		public var isParseFail:Boolean = false;
		/** 数据对应的URL，用来释放资源用 */
		public var url:String;
		
		private var _rate:int = 60;
		/**
		 * 解析骨骼动画数据
		 * @param	skeletonData	骨骼动画信息及纹理分块信息
		 * @param	texture			骨骼动画用到的纹理
		 * @param	playbackRate	缓冲的帧率数据（会根据帧率去分帧）
		 */
		public function parseData(texture:Texture, skeletonData:ArrayBuffer, playbackRate:int = 60):void {
			_mainTexture = texture;
			_rate = playbackRate;
			parse(skeletonData, playbackRate);
		}
		
		/**
		 * 创建动画
		 * 0,使用模板缓冲的数据，模板缓冲的数据，不允许修改					（内存开销小，计算开销小，不支持换装）
		 * 1,使用动画自己的缓冲区，每个动画都会有自己的缓冲区，相当耗费内存	（内存开销大，计算开销小，支持换装）
		 * 2,使用动态方式，去实时去画										（内存开销小，计算开销大，支持换装,不建议使用）
		 * @param	aniMode 0	动画模式，0:不支持换装,1,2支持换装
		 * @return
		 */
		public function buildArmature(aniMode:int = 0):Skeleton {
			return new Skeleton(this, aniMode);
		}
		
		/**
		 * @private
		 * 解析动画
		 * @param	data			解析的二进制数据
		 * @param	playbackRate	帧率
		 */
		override public function parse(data:ArrayBuffer, playbackRate:int):void {
			super.parse(data, playbackRate);
			//解析公共数据
			if (_loaded) {
				_parsePublicExtData();
				this.event(Event.COMPLETE, this);
			} else {
				this.event(Event.ERROR, this);
				isParseFail = true;
			}
		}
		
		/**
		 * 解析自定义数据
		 */
		private function _parsePublicExtData():void {
			var i:int = 0, j:int = 0, k:int = 0, n:int = 0;
			for (i = 0, n = getAnimationCount(); i < n; i++) {
				_graphicsCache.push([]);
			}
			var tByte:Byte = new Byte(getPublicExtData());
			var tX:Number = 0, tY:Number = 0, tWidth:Number = 0, tHeight:Number = 0;
			var tFrameX:Number = 0, tFrameY:Number = 0, tFrameWidth:Number = 0, tFrameHeight:Number = 0;
			var tTempleData:Number = 0;
			var tTextureLen:int = tByte.getUint8();
			var tTextureName:String = tByte.readUTFString();
			var tTextureNameArr:Array = tTextureName.split("\n");
			for (i = 0; i < tTextureLen; i++) {
				tTextureName = tTextureNameArr[i];
				tX = tByte.getFloat32();
				tY = tByte.getFloat32();
				tWidth = tByte.getFloat32();
				tHeight = tByte.getFloat32();
				
				tTempleData = tByte.getFloat32();
				tFrameX = isNaN(tTempleData) ? 0 : tTempleData;
				tTempleData = tByte.getFloat32();
				tFrameY = isNaN(tTempleData) ? 0 : tTempleData;
				tTempleData = tByte.getFloat32();
				tFrameWidth = isNaN(tTempleData) ? tWidth : tTempleData;
				tTempleData = tByte.getFloat32();
				tFrameHeight = isNaN(tTempleData) ? tHeight : tTempleData;
				subTextureDic[tTextureName] = Texture.create(_mainTexture, tX, tY, tWidth, tHeight, -tFrameX, -tFrameY, tFrameWidth, tFrameHeight);
			}
			
			var tMatrixDataLen:int = tByte.getUint16();
			var tLen:int = tByte.getUint16();
			var parentIndex:int;
			var boneLength:int = Math.floor(tLen / tMatrixDataLen);
			
			var tMatrixArray:Array = srcBoneMatrixArr;
			for (i = 0; i < boneLength; i++) {
				var tResultTransform:Transform = new Transform();
				tResultTransform.scX = tByte.getFloat32();
				tResultTransform.skX = tByte.getFloat32();
				tResultTransform.skY = tByte.getFloat32();
				tResultTransform.scY = tByte.getFloat32();
				tResultTransform.x = tByte.getFloat32();
				tResultTransform.y = tByte.getFloat32();
				tMatrixArray.push(tResultTransform);
			}
			
			//创建插槽并绑定到骨骼上
			var tBoneSlotLen:int = tByte.getInt16();
			var tDBBoneSlot:BoneSlot;
			var tDBBoneSlotArr:Array;
			for (i = 0; i < tBoneSlotLen; i++) {
				tDBBoneSlot = new BoneSlot();
				tDBBoneSlot.name = tByte.readUTFString();
				tDBBoneSlot.parent = tByte.readUTFString();
				tDBBoneSlot.srcDisplayIndex = tDBBoneSlot.displayIndex = tByte.getInt16();
				tDBBoneSlot.templet = this;
				boneSlotDic[tDBBoneSlot.name] = tDBBoneSlot;
				
				tDBBoneSlotArr = bindBoneBoneSlotDic[tDBBoneSlot.parent];
				if (tDBBoneSlotArr == null) {
					bindBoneBoneSlotDic[tDBBoneSlot.parent] = tDBBoneSlotArr = [];
				}
				tDBBoneSlotArr.push(tDBBoneSlot);
				boneSlotArray.push(tDBBoneSlot);
			}
			for (i = 0; i < boneSlotArray.length; i++) {
				tDBBoneSlot = boneSlotArray[i];
			}
			
			var tNameString:String = tByte.readUTFString();
			var tNameArray:Array = tNameString.split("\n");
			var tNameStartIndex:int = 0;
			
			var tSkinDataLen:int = tByte.getUint8();
			for (i = 0; i < tSkinDataLen; i++) {
				var tSkinData:SkinData = new SkinData();
				tSkinData.name = tNameArray[tNameStartIndex++];
				var tSlotDataLen:int = tByte.getUint8();
				
				for (j = 0; j < tSlotDataLen; j++) {
					var tSlotData:SlotData = new SlotData();
					tSlotData.name = tNameArray[tNameStartIndex++];
					tDBBoneSlot = boneSlotDic[tSlotData.name];
					var tDisplayDataLen:int = tByte.getUint8();
					for (k = 0; k < tDisplayDataLen; k++) {
						var tDisplayData:SkinSlotDisplayData = new SkinSlotDisplayData();
						tDisplayData.name = tNameArray[tNameStartIndex++];
						tDisplayData.transform = new Transform();
						tDisplayData.transform.scX = tByte.getFloat32();
						tDisplayData.transform.skX = tByte.getFloat32();
						tDisplayData.transform.skY = tByte.getFloat32();
						tDisplayData.transform.scY = tByte.getFloat32();
						tDisplayData.transform.x = tByte.getFloat32();
						tDisplayData.transform.y = tByte.getFloat32();
						tSlotData.displayArr.push(tDisplayData);
					}
					tSkinData.slotArr.push(tSlotData);
				}
				skinDic[tSkinData.name] = tSkinData;
				skinDataArray.push(tSkinData);
			}
			showSkinByIndex(boneSlotDic, 0);
		}
		
		/**
		 * 得到指定的纹理
		 * @param	name	纹理的名字
		 * @return
		 */
		public function getTexture(name:String):Texture {
			return subTextureDic[name];
		}
		
		/**
		 * @private
		 * 显示指定的皮肤
		 * @param	boneSlotDic	插糟字典的引用
		 * @param	skinIndex	皮肤的索引
		 */
		public function showSkinByIndex(boneSlotDic:Object, skinIndex:int):void {
			
			if (skinIndex < 0 && skinIndex >= skinDataArray.length) return;
			var i:int, n:int;
			var tBoneSlot:BoneSlot;
			var tSlotData:SlotData;
			var tSkinData:SkinData = skinDataArray[skinIndex];
			if (tSkinData) {
				for (i = 0, n = tSkinData.slotArr.length; i < n; i++) {
					tSlotData = tSkinData.slotArr[i];
					if (tSlotData) {
						tBoneSlot = boneSlotDic[tSlotData.name];
						if (tBoneSlot) {
							tBoneSlot.showSlotData(tSlotData);
							tBoneSlot.showDisplayByIndex(tBoneSlot.displayIndex);
						}
					}
				}
			}
		}
		
		/**
		 * @private
		 * 显示指定的皮肤
		 * @param	boneSlotDic	插糟字典的引用
		 * @param	skinName	皮肤的名字
		 */
		public function showSkinByName(boneSlotDic:Object, skinName:String):void {
			var i:int, n:int;
			var tBoneSlot:BoneSlot;
			var tSlotData:SlotData;
			var tSkinData:SkinData = skinDic[skinName];
			if (tSkinData) {
				for (i = 0, n = tSkinData.slotArr.length; i < n; i++) {
					tSlotData = tSkinData.slotArr[i];
					if (tSlotData) {
						tBoneSlot = boneSlotDic[tSlotData.name];
						if (tBoneSlot) {
							tBoneSlot.showSlotData(tSlotData);
							tBoneSlot.showDisplayByIndex(tBoneSlot.displayIndex);
						}
					}
				}
			}
		}
		
		/**
		 * @private
		 * 得到缓冲数据
		 * @param	aniIndex	动画索引
		 * @param	frameIndex	帧索引
		 * @return
		 */
		public function getGrahicsDataWithCache(aniIndex:int, frameIndex:Number):Graphics {
			return _graphicsCache[aniIndex][frameIndex];
		}
		
		/**
		 * @private
		 * 保存缓冲grahpics
		 * @param	aniIndex	动画索引
		 * @param	frameIndex	帧索引
		 * @param	graphics	要保存的数据
		 */
		public function setGrahicsDataWithCache(aniIndex:int, frameIndex:int, graphics:Graphics):void {
			_graphicsCache[aniIndex][frameIndex] = graphics;
		}
		
		/**
		 * 预留
		 */
		public function destory():void {
			if (url) {
				delete TEMPLET_DICTIONARY[url];
			}
		}
		
		/***********************************下面为一些儿访问接口*****************************************/
		/**
		 * 通过索引得动画名称
		 * @param	index
		 * @return
		 */
		public function getAniNameByIndex(index:int):String {
			var tAni:* = getAnimation(index);
			if (tAni) return tAni.name;
			return null;
		}
		
		public function get rate():Number {
			return _rate;
		}
	}
}