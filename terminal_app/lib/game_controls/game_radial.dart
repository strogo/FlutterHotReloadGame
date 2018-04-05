import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "dart:typed_data";
import "package:flutter/scheduler.dart";
import "game_colors.dart";

class GameRadial extends StatefulWidget 
{
	GameRadial({Key key, this.value = 40, this.min = 0, this.max = 200}) : super(key: key);

	final int value;
	final int min;
	final int max;

	@override
	_GameRadialState createState() => new _GameRadialState(value, min, max);
}

class _GameRadialState extends State<GameRadial>  with SingleTickerProviderStateMixin
{
	AnimationController _controller;
	Animation<double> _slideAnimation;
	int value = 0;
	final int minValue;
	final int maxValue;

	_GameRadialState(this.value, this.minValue, this.maxValue);
	
	void dragStart(DragStartDetails details)
	{
		//_controller.stop();
	}

	void dragUpdate(DragUpdateDetails details)
	{
		//context.size
		// RenderBox ro = context.findRenderObject();
		// if(ro == null)
		// {
		// 	return;
		// }
		// Offset local = ro.globalToLocal(details.globalPosition);
		setState(()
		{
			value = min(maxValue, max(minValue, (value - (details.delta.dy/context.size.height) * (maxValue-minValue)).round()));
		});
	}

	void dragEnd(DragEndDetails details)
	{
		// _slideAnimation = new Tween<double>(
		// 	begin: scroll,
		// 	end: -min((data.length-1).toDouble(), max(0.0, -scroll.roundToDouble()))
		// ).animate(_controller);
	
		// _controller
		// 	..value = 0.0
		// 	..fling(velocity: details.velocity.pixelsPerSecond.distance / 1000.0);
	}

	initState() 
	{
    	super.initState();
    	_controller = new AnimationController(vsync: this);
		_controller.addListener(()
		{
			setState(()
			{
				//scroll = _slideAnimation.value;
			});
		});
	}

	@override
	void dispose()
	{
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) 
	{
		return new GestureDetector(
			onVerticalDragStart: dragStart,
			onVerticalDragUpdate: dragUpdate,
			onVerticalDragEnd: dragEnd,
			child: new Container(
				alignment:Alignment.center,
				child:new GameRadialNotches((value-minValue)/(maxValue-minValue), minValue, maxValue)
				)
			);
	}
}


class GameRadialNotches extends LeafRenderObjectWidget
{
	final double value;
	final int minValue;
	final int maxValue;

	GameRadialNotches(this.value, this.minValue, this.maxValue,
		{
			Key key
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new GameRadialNotchesRenderObject(value, minValue, maxValue);
	}

	@override
	void updateRenderObject(BuildContext context, covariant GameRadialNotchesRenderObject renderObject)
	{
		renderObject..value = value
					..minValue = minValue
					..maxValue = maxValue;
	}
}

const double ArrowWidth = 16.0;
const double ArrowHeight = 10.0;

const int NumRadialTicks = 5;
class RadialTickParagraph
{
	ui.Paragraph paragraph;
	Size size;
}

class GameRadialNotchesRenderObject extends RenderBox
{
	double _value;
	int _minValue;
	int _maxValue;

	ui.Paragraph _valueParagraph;
	Size _valueLabelSize;

	ui.Path _arrowPath;

	List<RadialTickParagraph> _tickParagraphs;

	GameRadialNotchesRenderObject(double value, int minValue, int maxValue)
	{
		this.value = value;
		this.minValue = minValue;
		this.maxValue = maxValue;

		_arrowPath = new ui.Path();
		_arrowPath.moveTo(-ArrowWidth/2.0, 0.0);
		_arrowPath.lineTo(0.0, -ArrowHeight);
		_arrowPath.lineTo(ArrowWidth/2.0, 0.0);
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = new Size(constraints.constrainWidth(), constraints.constrainHeight(240.0));
	}

	@override
	void performLayout()
	{
		super.performLayout();
		
		_tickParagraphs = new List<RadialTickParagraph>(NumRadialTicks);

		String valueLabel = (_minValue + _value*(_maxValue-_minValue)).round().toString();
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: "Inconsolata",
			fontSize: 18.0,
			fontWeight: FontWeight.w700
		))..pushStyle(new ui.TextStyle(color:GameColors.highValueContent));
		builder.addText(valueLabel);
		_valueParagraph = builder.build();

		_valueParagraph.layout(new ui.ParagraphConstraints(width: size.width));
		List<ui.TextBox> boxes = _valueParagraph.getBoxesForRange(0, valueLabel.length);
		_valueLabelSize = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);

		for(int i = 0; i < NumRadialTicks; i++)
		{
			String tickLabel = (_minValue + (1.0/(NumRadialTicks-1) * i) * (_maxValue-_minValue)).round().toString();
			ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
				textAlign:TextAlign.start,
				fontFamily: "Inconsolata",
				fontSize: 14.0
			))..pushStyle(new ui.TextStyle(color:GameColors.lowValueContent));
			builder.addText(tickLabel);
			ui.Paragraph tickParagraph = builder.build();
			tickParagraph.layout(new ui.ParagraphConstraints(width: size.width));
			List<ui.TextBox> boxes = tickParagraph.getBoxesForRange(0, tickLabel.length);
			RadialTickParagraph rtp = new RadialTickParagraph()
															..paragraph = tickParagraph
															..size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);
			_tickParagraphs[i] = rtp;
			
		}
	}
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		const padding = 40.0;
		double open = 0.25;
		double sweep = pi*2.0*(1.0-open);

		Offset pos = new Offset(padding+offset.dx, padding + offset.dy);
		Size arcSize = new Size(size.width-padding*2, size.height-padding*2);

		
		final double startAngle = pi/2.0+(pi*open);
		const double tickLength = 25.0;
		const double tickTextLength = 35.0;
		final double radius = min(arcSize.width, arcSize.height)/2.0;

		final double radiusTickStart = radius-tickLength/2.0;
		final double radiusTickEnd = radius+tickLength/2.0;
		final double radiusTickText = radius+tickTextLength;

		ui.Paint tickPaint = new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 2.0..style=PaintingStyle.stroke;

		Offset center = new Offset(pos.dx + arcSize.width/2.0, pos.dy + arcSize.height/2.0);
		Offset arcPaintOffset = new Offset(pos.dx + arcSize.width/2.0 - radius, pos.dy + arcSize.height/2.0 - radius);
		Size arcPaintSize = new Size(radius*2.0, radius*2.0);
		for(int i = 0; i < NumRadialTicks; i++)
		{
			double angle = startAngle + i * sweep/(NumRadialTicks-1);

			double c = cos(angle);
			double s = sin(angle);

			Offset p1 = new Offset(center.dx+c * radiusTickStart, center.dy+s * radiusTickStart);
			Offset p2 = new Offset(center.dx+c * radiusTickEnd, center.dy+s * radiusTickEnd);

			if(_tickParagraphs != null)
			{
				RadialTickParagraph tickParagraph = _tickParagraphs[i];
				Offset tickTextPosition = new Offset(center.dx+c * radiusTickText, center.dy+s * radiusTickText);
				canvas.drawParagraph(tickParagraph.paragraph, new Offset(tickTextPosition.dx - tickParagraph.size.width/2.0, tickTextPosition.dy - tickParagraph.size.height/2.0));
			}
			

			canvas.drawLine(p1, p2, tickPaint);
		}
		canvas.drawArc(arcPaintOffset & arcPaintSize, startAngle, sweep, false, new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 5.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
		canvas.drawArc(arcPaintOffset & arcPaintSize, startAngle, sweep*value, false, new ui.Paint()..color = GameColors.highValueContent..strokeWidth = 5.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);

		
		ui.Paint arrowPaint = new ui.Paint()..color = GameColors.highValueContent..strokeWidth = 1.0..style=PaintingStyle.stroke;
		canvas.drawParagraph(_valueParagraph, new Offset(center.dx - _valueLabelSize.width/2.0, center.dy - _valueLabelSize.height/2.0));
		canvas.save();
		canvas.translate(center.dx, center.dy - 20.0);
		canvas.drawPath(_arrowPath, arrowPaint);
		canvas.restore();
		canvas.save();
		
		canvas.translate(center.dx, center.dy + 20.0);
		canvas.scale(1.0, -1.0);
		canvas.drawPath(_arrowPath, arrowPaint);
		canvas.restore();
		
		
	}

	double get value
	{
		return _value;
	}

	set value(double v)
	{
		if(_value == v)
		{
			return;
		}
		_value = v;

		markNeedsLayout();
		markNeedsPaint();
	}

	int get minValue
	{
		return _minValue;
	}

	set minValue(int v)
	{
		if(_minValue == v)
		{
			return;
		}
		_minValue = v;

		// ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
		// 	textAlign:TextAlign.start,
		// 	fontFamily: "Inconsolata",
		// 	fontSize: 18.0,
		// 	fontWeight: FontWeight.w700
		// ))..pushStyle(new ui.TextStyle(color:GameColors.highValueContent));
		// builder.addText((_valueLabel=_value.toString()));
		// _valueParagraph = builder.build();

		markNeedsLayout();
		markNeedsPaint();
	}

	int get maxValue
	{
		return _maxValue;
	}

	set maxValue(int v)
	{
		if(_maxValue == v)
		{
			return;
		}
		_maxValue = v;

		// ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
		// 	textAlign:TextAlign.start,
		// 	fontFamily: "Inconsolata",
		// 	fontSize: 18.0,
		// 	fontWeight: FontWeight.w700
		// ))..pushStyle(new ui.TextStyle(color:GameColors.highValueContent));
		// builder.addText((_valueLabel=_value.toString()));
		// _valueParagraph = builder.build();

		markNeedsLayout();
		markNeedsPaint();
	}
}