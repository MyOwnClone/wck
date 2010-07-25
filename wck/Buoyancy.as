﻿package wck {		import Box2DAS.*;	import Box2DAS.Collision.*;	import Box2DAS.Collision.Shapes.*;	import Box2DAS.Controllers.*;	import Box2DAS.Common.*;	import Box2DAS.Dynamics.*;	import Box2DAS.Dynamics.Contacts.*;	import Box2DAS.Dynamics.Joints.*;	import cmodule.Box2D.*;	import wck.*;	import misc.*;	import flash.utils.*;	import flash.events.*;	import flash.display.*;	import flash.text.*;	import flash.geom.*;	import flash.ui.*;		/**	 * Can be extended to create a buoyant box object.	 */	public class Buoyancy extends BodyShape {				[Inspectable(defaultValue=1.5)]		public var liquidDensity:Number = 1.5;				[Inspectable(defaultValue=5)]		public var liquidLinearDrag:Number = 5;				[Inspectable(defaultValue=1)]		public var liquidAngularDrag:Number = 1;				[Inspectable(defaultValue=true)]		public var liquidUseDensity:Boolean = true;				[Inspectable(defaultValue=0)]		public var liquidSurfaceOffset:Number = 0;				[Inspectable(defaultValue=false)]		public var liquidWaves:Boolean = false;				public var c:b2Controller;		public var be:b2BuoyancyEffect;		public var cl:ContactList;		public var localOffset:Number;		public var water:Waves;		public var waterShape:Shape;		public var splashes:Dictionary;				public override function shapes():void {			box();		}				public override function create():void { 			cl = new ContactList();			cl.listenTo(this);			var b:Rectangle = Util.bounds(this);			localOffset = b.top;			isSensor = true;			mouseEnabled = false;			reportBeginContact = true;			reportEndContact = true;			super.create();			be = new b2BuoyancyEffect();			be.density = liquidDensity;			be.linearDrag = liquidLinearDrag;			be.angularDrag = liquidAngularDrag;			be.useDensity = liquidUseDensity;			listenWhileVisible(world, StepEvent.STEP, handleTimeStep, false, 1);						if(liquidWaves) {				// Need to figure out the surface of the water in the coordinate space of the world.				var topLeft:Point = Util.localizePoint(world, this, new Point(b.left, b.top));				var topRight:Point = Util.localizePoint(world, this, new Point(b.right, b.top));				var bottomRight:Point = Util.localizePoint(world, this, new Point(b.right, b.bottom));				var w:Number = Point.distance(topLeft, topRight);				var h:Number = Point.distance(topRight, bottomRight);				water = new Waves(w, h - liquidSurfaceOffset, w / 10);				waterShape = new Shape();				Util.removeChildren(this);				addChild(waterShape);				var m:Matrix = matrix.clone();				m.invert();				waterShape.transform.matrix = m;				waterShape.x = -b.width / 2;				waterShape.y = -b.height / 2 + liquidSurfaceOffset * (b.height / h);				water.createTurbulance(10, 5, 100);				water.createTurbulance(10, -5, 200);				splashes = new Dictionary();			}		}				public function handleTimeStep(e:StepEvent):void {			var v1:V2 = V2.fromP(Util.localizePoint(world, this));			var v2:V2 = V2.fromP(Util.localizePoint(world, this, new Point(0, localOffset)));			be.normal = V2.subtract(v2, v1).normalize();			var dot:Number = v2.dot(be.normal);			be.offset = (dot - liquidSurfaceOffset) / world.scale;			be.velocity = V2.multiplyN(b2body.m_linearVelocity.v2, world.timeStep);			var v:Array = cl.values;			cl.clean();						for(var i:int = 0; i < v.length; ++i) {							var ce:ContactEvent = v[i];				var f:b2Fixture = ce.other;											if(liquidWaves) {					var before:Boolean = ce.userData as Boolean;					var p:Point = Util.localizePoint(waterShape, f.m_userData as BodyShape); // Find actual center for fixture...					var x:Number = p.x;					var y:Number = water.valueAt(x) / world.scale;					be.offset -= y;					var after:Boolean = be.ApplyToFixture(f);					be.offset += y;					if(after != before && !splashes[f.m_body]) {						var p2:Point = Util.localizePoint(waterShape, ce.relatedObject);						trace(f.m_body.m_linearVelocity.v2.length());						var splashStrength:Number = f.m_body.m_linearVelocity.v2.length() * 6;						water.createSplash(p2.x, splashStrength, 300, 30);						splashes[f.m_body] = 15;					}					ce.userData = after;				}				else {					be.ApplyToFixture(f);				}			}						if(liquidWaves) {				for(var o:* in splashes) {					splashes[o]--;					if(splashes[o] == 0) {						delete splashes[o];					}				}				water.step();				renderWater(water.stroke());							}		}				public function renderWater(stroke:GraphicsPath):void {			var g:Graphics = waterShape.graphics;			g.clear();			g.lineStyle(1, 0xffffff);			g.beginFill(0x5FA5FF, 0.5);			g.drawGraphicsData(Vector.<IGraphicsData>([stroke]));			g.endFill();		}	}}