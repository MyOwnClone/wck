﻿package misc {		import misc.*;	import flash.display.*;	import flash.events.*;	import flash.geom.*;		/**	 * A class to add simple constructor / destructor functionality to movieclips based on when they are added	 * and removed from the visible display hierarchy. To get this functionality, MovieClips must extend this class.	 *	 * Child classes also get the listenWhileVisible() and stopListening() functions which are alternatives to 	 * addEventListener() and removeEventListener(). Listeners registered this way will be automatically removed	 * at the same time destroy() is called.	 *	 * The pseudo-constructor function, create():	 * 1. Has access to component property values set in Flash (the true constructor doesn't).	 * 2. Is called before the object is visible.	 * 3. Is not guaranteed to be called on parents/ancestors first. Child nodes can call ensureCreate() on parents	 * if they should be created first.	 *	 * The pseudo-destructor function, destroy() is called when the object is removed from the stage. 	 *	 * This class also adds simple mouse dragging event handlers that can be overridden to implement	 * mouse movement. If the "Input" class is initialized, dragging will take into account when the	 * mouse leaves the stage or Flash loses focus, and will clamp mouse dragging to the edge of the 	 * stage.	 */	public class Entity extends MovieClip {				[Inspectable(defaultValue=false)]		public var disabled:Boolean = false;				public var listeningTo:DictionaryTree = new DictionaryTree();		public var created:Boolean = false;		public var dragging:Boolean = false;		public var mouseHover:Boolean = false;				/// Override this - pseudo-constructor		public function create():void {}				/// Override this - pseudo-destroyer		public function destroy():void {}				/**		 * Makes sure create() is called, but only once. This is handy for co-dependent entities sensitive to the order		 * in which they are created. The dependent entity can call this on the other entity to make sure it is created.		 */		public function ensureCreated():void { 			if(!created && !disabled) {				created = true;				create();				addEventListener(Event.REMOVED_FROM_STAGE, handleRemovedFromStage);				listenWhileVisible(this, MouseEvent.MOUSE_DOWN, handleDragStart);				listenWhileVisible(this, MouseEvent.ROLL_OVER, handleRollOver);				listenWhileVisible(this, MouseEvent.ROLL_OUT, handleRollOut);			}		}				/**		 * For the same reasons as ensureCreate(), but for destruction. Also gets rid of all the "listenWhileVisible"		 * event handlers. If the entity is being mouse-dragged, "handleMouseUp" will be called to stop dragging.		 */		public function ensureDestroyed():void { 			if(created && !disabled) {				addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);				removeAllListeners();				destroy();				if(dragging) {					handleDragStop(null);				}				created = false;			}		}				/**		 * Setup some event handlers that are neccessary to determine when the entity is visible.		 */		public function Entity() {			addEventListener(Event.ADDED_TO_STAGE, stage ? handlePublishedOnStage : handleAddedToStage);		}				/**		 * This delays the call to ensureCreate() when the Entity is published on the stage. In this case,		 * ADDED_TO_STAGE event handlers don't have access to component properties yet!		 */		public function handlePublishedOnStage(e:Event):void {			if(stage) {				var self:Entity = this;				var s:Stage = stage;				stage.invalidate();				var f:Function = function(e:Event):void {					if(self.stage) {						self.ensureCreated();					}					s.removeEventListener(Event.RENDER, f);				}				stage.addEventListener(Event.RENDER, f);			}			removeEventListener(Event.ADDED_TO_STAGE, handlePublishedOnStage);			addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);		}								/**		 * Call the create() function when added to the visible display hierarchy.		 */		public function handleAddedToStage(e:Event):void {			ensureCreated();		}				/**		 * Call the destroy() function when removed from the visible display hierarchy.		 */		public function handleRemovedFromStage(e:Event):void {			ensureDestroyed();		}				/**		 * Listeners added using this function will be automatically removed when the entity is removed.		 * Call this like you would addEventListener in your create() function. 		 * NOTE: if you're listening to an ENTER_FRAME event on ANOTHER object, the listener will still		 * be called if the target is no longer on the stage. You can use Util.stopInvisibleEnterFrame() to		 * fix that. If an entity is listening to its OWN ENTER_FRAME event, just listenWhileVisible() will		 * work fine.		 */		public function listenWhileVisible(ed:EventDispatcher, type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {			ed.addEventListener(type, listener, useCapture, priority, useWeakReference);			listeningTo.store([ed, type, listener, useCapture], 1);		}				/**		 * Like listenWhileVisible, but the listener will only be called once.		 */		public function listenOnceWhileVisible(ed:EventDispatcher, type:String, listener:Function, useCapture:Boolean = false, priority:int = 0):void {			var f:Function = function(e:Event):void {				listener(e);				stopListening(ed, type, f, useCapture);			}			listenWhileVisible(ed, type, f, useCapture, priority);		}				/**		 *		 */		public function listenNTimesWhileVisible(n:int, ed:EventDispatcher, type:String, listener:Function, useCapture:Boolean = false, priority:int = 0):void {			var i:int = 0;			var f:Function = function(e:Event):void {				listener(e, i);				if(++i == n) {					stopListening(ed, type, f, useCapture);				}			}			if(n > 0) {				listenWhileVisible(ed, type, f, useCapture, priority);			}		}				/**		 * Remove a listener added via listenWhileVisible().		 */		public function stopListening(ed:EventDispatcher, type:String, listener:Function, useCapture:Boolean = false):void {			ed.removeEventListener(type, listener, useCapture);			listeningTo.remove([ed, type, listener, useCapture]);		}				/**		 * Get rid of all the listeners added via listenWhileVisible().		 */		public function removeAllListeners():void {			listeningTo.forEach(function(keys:Array, val:uint):void {				stopListening(keys[0], keys[1], keys[2], keys[3] as Boolean);			}, this);		}				/**		 * Start tracking a mouse-drag. Works best with the "Input" class - dragging will stop		 * if flash loses control of the mouse.		 */		public function handleDragStart(e:Event):void {			listenWhileVisible(stage, Event.ENTER_FRAME, handleDragStep, false, 1000);			listenWhileVisible(stage, Input.initialized ? Input.MOUSE_UP_OR_LOST : MouseEvent.MOUSE_UP, handleDragStop);			dragging = true;		}				/**		 * override to implement mouse movement. This is called on enter frame, rather than on mouse move, in case		 * the stage / visible area is moving but the mouse is not. The input class can be used to determine		 * where the mouse is located.		 */		public function handleDragStep(e:Event):void {		}				/**		 * Stop mouse dragging.		 */		public function handleDragStop(e:Event):void {			if(stage) {				stopListening(stage, Event.ENTER_FRAME, handleDragStep);				stopListening(stage, Input.MOUSE_UP_OR_LOST, handleDragStop);				stopListening(stage, MouseEvent.MOUSE_UP, handleDragStop);			}			dragging = false;		}				/**		 * Override to handle roll over events.		 */		public function handleRollOver(e:MouseEvent):void {			mouseHover = true;		}				/**		 * Override to handle roll out events.		 */		public function handleRollOut(e:MouseEvent):void {			mouseHover = false;		}				/**		 * Remove the entity. Has dummy arguments so it can be an event listener.		 */		public function remove(...rest):void {			Util.remove(this);		}				/**		 * Set the position from a point or other object.		 */		public function setPos(p:*):void {			Util.setPos(this, p);		}	}}