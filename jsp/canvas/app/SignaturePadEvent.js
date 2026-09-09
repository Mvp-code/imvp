var canvasOffsetLeft,   // the left offset for the canvas elements
canvasOffsetTop,    // the top offset for the canvas elements
drawingCanvas,      // canvas element for the drawing canvas
drawingCanvasCxt,   // 2D drawing context for the drawing canvas
overlayCanvas,      // canvas element for the overlay canvas
overlayCanvasCxt,   // 2D drawing context for the overlay canvas
outputImage,        // output image
currentBrush,       // the brush selected to paint on the drawing canvas
strokeColour,       // the span element showing the current stroke colour
currentColour,      // what's the colour to use with the current brush
backgroundColour,   // the background colour
brushes;            // the available brushes

 // define a signature brush for drawing free-hand lines
var SignBrush = Class.create({
    initialize: function (lineWidth, drawingCxt, canvaso) {
        this.lineWidth = 2;
		var tool = this;
		this.started = false;

        this.setColour = function (colour) {
            drawingCxt.fillStyle = drawingCxt.strokeStyle = "#000000";
            drawingCxt.lineWidth = 2;
            drawingCxt.lineCap = "round";
            drawingCxt.lineJoin = "round";
        };

		// Capture Mouse events starts
		canvaso.addEventListener("mousedown", function(event){
			var position = getMouseXYPosition(event);
			tool.started = true;
            drawingCxt.beginPath();
            drawingCxt.moveTo(position.X--, position.Y--);
            drawingCxt.lineTo(position.X, position.Y);
            drawingCxt.stroke();
		})
		canvaso.addEventListener("mouseup", function (event) {
			if (tool.started) {
				tool.started = false;
				//img_update(drawingContext);
			}
		})
		canvaso.addEventListener("mousemove", function (event) {
			 var position = getMouseXYPosition(event);
			 if (!tool.started) {
				return;
			}
             drawingCxt.lineTo(position.X, position.Y);
             drawingCxt.stroke();
		})
		// Capture Mouse events ends
		
		// Capture Touch events starts
		canvaso.addEventListener("touchstart", function (event) {
			var position = getTouchPos(canvaso,event);
			tool.started = true;
            drawingCxt.beginPath();
            drawingCxt.moveTo(position.X--, position.Y--);
            drawingCxt.lineTo(position.X, position.Y);
            drawingCxt.stroke();
		})
		canvaso.addEventListener("touchend", function (event) {
			if (tool.started) {
				tool.started = false;
				//img_update(drawingContext);
			}
		})
		canvaso.addEventListener("touchmove", function (event) {
			 var position = getTouchPos(canvaso,event);
			 if (!tool.started) {
				return;
			}
             drawingCxt.lineTo(position.X, position.Y);
             drawingCxt.stroke();
		})
		// prevent elastic scrolling
		canvaso.addEventListener('touchmove',function(event){
			event.preventDefault();
		},false);
		// Capture Touch events ends
    }
});

function clearCanvas(canvasContext, canvas) {
  canvasContext.clearRect(0, 0, canvas.width, canvas.height);
  var w = canvas.width;
  canvas.width = 1;
  canvas.width = w;
}
function getTouchPos(canvasDom, touchEvent) {
    var rect = canvasDom.getBoundingClientRect();
    return {
      X: touchEvent.touches[0].clientX - rect.left,
      Y: touchEvent.touches[0].clientY - rect.top
    }
  }

  function getMouseXYPosition (ev) {
    if (ev.layerX || ev.layerX == 0) { // Firefox
      ev._x = ev.layerX;
      ev._y = ev.layerY;
    } else if (ev.offsetX || ev.offsetX == 0) { // Opera
      ev._x = ev.offsetX;
      ev._y = ev.offsetY;
    }
	 return { X: ev._x, Y: ev._y };
  }
var finalCanvas,finalContext,srcCanvas;
var loadedCanvas,lodedCtx,loadedImg;
let scale = 1;
const scaleFactor = 1.1;
function browseCanvas(id,signContext, signCanvas){
	finalCanvas = signCanvas;
	finalContext = signContext;
	let title = "Browse";
	
	var popupHeight = jQuery(window).height()-300;
	var popupWidth = jQuery(window).width()-300;
	if(popupWidth<320){
		popupWidth = 320
	}
	var htmlContent = '<div class="col-12">';
	htmlContent += '		<div class="row form-row">';
	htmlContent += '			<div class="section-title text-center col-12" >'+title;
	htmlContent += '			</div>';
	htmlContent += '		</div>';
	htmlContent += '		<div class="row form-row form-group form-group-sm tiny-content">';	
	htmlContent += '			<div class="col-12 " id="canvasSelectDiv">'
	htmlContent += '				<input type="file" id="signImageLoader" name="signImageLoader" style="display:none"/>';
	htmlContent += '				<canvas id="signImageCanvas" style></canvas>';
	htmlContent += '				<canvas id="selectCanvas"></canvas>';
	htmlContent += ' 				<div id="buttonWrapper" >';
	htmlContent += ' 					<button id="browseCanvasIcon" title="browse"><i class="fa fa-file text-danger" aria-hidden="true"></i></button>'
	htmlContent += ' 					<button id="zoomIn" title="Zoom In"><i class="fa fa-plus-square text-danger" aria-hidden="true"></i></button>'
	htmlContent += ' 					<button id="zoomOut" title="Zoom Out"><i class="fa fa-minus-square text-danger" aria-hidden="true"></i></button>'
	htmlContent += '				</div>'
	htmlContent += '				<div id="downloadContainer">';
	htmlContent += '					<div class="label">';
	htmlContent += '						<a href="javascript:doneCanvas()" class="single-char-button" style="background-color:#0000FF;" title="Nurse">Done</a>';
	htmlContent += '					</div>';
	htmlContent += '					<img id="targetImage">';
	htmlContent += '				</div>';
	htmlContent += '			</div>';
	htmlContent += '		</div>';	
	htmlContent += '</div>';	
	htmlContent += '<style>';
	htmlContent += '#canvasSelectDiv body, canvasSelectDiv div, canvasSelectDiv canvas, canvasSelectDiv img {';
	htmlContent += '  margin: 0;';
	htmlContent += '  padding: 0;';
	htmlContent += '}';
	htmlContent += '#canvasSelectDiv #targetImage {';
	htmlContent += '  display: none;';
	htmlContent += '  position: absolute;';
	htmlContent += '  left: 0;';
	htmlContent += '  top: 0;border: 1px solid black;';
	htmlContent += '}';
	htmlContent += '#canvasSelectDiv canvas {';
	htmlContent += '  display: block;';
	htmlContent += '}';
	htmlContent += '#canvasSelectDiv #signImageCanvas, #canvasSelectDiv #selectCanvas, #canvasSelectDiv #downloadContainer {';
	htmlContent += '    position: absolute;';
	htmlContent += '}';
	htmlContent += '#canvasSelectDiv #downloadContainer {';
	htmlContent += '  visibility: hidden;';
	htmlContent += '}';
	htmlContent += '#canvasSelectDiv #downloadContainer .label {';
	htmlContent += '  position: absolute;';
	htmlContent += '  width: 500px;';
	htmlContent += '  bottom: -30px;';
	htmlContent += '  font-family: sans-serif;';
	htmlContent += '  font-size: 17px;';
	htmlContent += '  color: #444;';
	htmlContent += '}';
	htmlContent += '#canvasSelectDiv #selectCanvas {';
	htmlContent += '  opacity: 0.5;';
	htmlContent += '  cursor: default;';
	htmlContent += '}';
	htmlContent += '#canvasSelectDiv #buttonWrapper {';
	htmlContent += '      position: fixed;';
	htmlContent += '      width: 30px;';
	htmlContent += '      top: 100px;';
	htmlContent += '     left: 2px;';
	htmlContent += '}';
	    
	htmlContent += '#canvasSelectDiv button {';
	htmlContent += '    padding: 5px;';
	htmlContent += '    width: 30px;';
	htmlContent += '    margin: 0px 0px 2px 0px;';
	htmlContent += '	border: 0px;';
	htmlContent += '	background: white;';
	htmlContent += '    }';
	htmlContent += '#canvasSelectDiv button i{';
	htmlContent += '     font-size: x-large;';
	htmlContent += '    }';
	
	htmlContent += '</style>';	
	TINY.box.show({
		html:htmlContent,
		fixed:false,
		maskid:'frameless',
		width:popupWidth,
		height:popupHeight,
		maskopacity:40,
		openjs:function() {
			resizePageTinySign();
			loadSignCanvas();
		},
		closejs:function(){
			jQuery("body").css("overflow","auto");
		}
	});
}

function doneCanvas(){
	image = new Image();

	image.src = srcCanvas.toDataURL('image/png');

	finalContext.drawImage(image, 0, 0);
	jQuery(".tclose").trigger("click");

}
function resizePageTinySign(){
	var popupWidth = jQuery(window).width()-300;
	if(popupWidth<320){
		popupWidth = 320
	}
	var popupHeight = jQuery(window).height()-200;
	var buttonheight = jQuery("#buttonWrapper").height();
	let buttonleft = jQuery('.tinner').offset().left;
	var buttonTop = (popupHeight-buttonheight)/2
	jQuery(".tinner").width(popupWidth);
	jQuery(".tinner").height(popupHeight);
	console.log("buttonTop="+buttonTop);
	jQuery("#buttonWrapper").css("top",buttonTop+"px");
	jQuery("#buttonWrapper").css("left",buttonleft+"px");
	jQuery(".tinner").css("overflow-y","auto");
	jQuery("body").css("overflow","hidden");
}
function loadSignCanvas(){
	var imageLoader = document.getElementById('signImageLoader');
	imageLoader.addEventListener('change', handleImage, false);
	var canvas = document.getElementById('signImageCanvas');
	var ctx = canvas.getContext('2d');
    function handleImage(e){
        var reader = new FileReader();
        reader.onload = function(event){
            var img = new Image();
            img.onload = function(){
				canvas.width = img.width;
				canvas.height = img.height;
				loadedCanvas = canvas;
				lodedCtx = ctx;
				loadedImg = img;
				//ctx.drawImage(img,0,0);
				//ctx.scale(0.5, 0.5);
				drawImage()
				jQuery("#downloadContainer").find("canvas").each(function(){
					jQuery(this).remove();
				})
				document.getElementById('zoomIn').addEventListener('click', () => {
				    scale *= scaleFactor;
				    drawImage();
				  });
				
				  document.getElementById('zoomOut').addEventListener('click', () => {
				    scale /= scaleFactor;
				    drawImage();
				  });
				  document.getElementById('browseCanvasIcon').addEventListener('click', () => {
					    
					  loadSignCanvas();
					  });
				  
				selectCanvasArea(canvas);
				resizePageTinySign();
            }
            img.src = event.target.result;
        }
        reader.readAsDataURL(e.target.files[0]); 
    }
	jQuery('#signImageLoader').trigger("click");
}
function drawImage() {
	let canvas = loadedCanvas;
	let ctx = lodedCtx;
	let image = loadedImg;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const x = canvas.width / 2 - (image.width / 2) * scale;
    const y = canvas.height / 2 - (image.height / 2) * scale;
    ctx.save();
    //ctx.translate(canvas.width / 2, canvas.height / 2);
    ctx.scale(scale, scale);
    //ctx.translate(-canvas.width / 2, -canvas.height / 2);
    ctx.drawImage(image, x, y, image.width * scale, image.height * scale);
    ctx.restore();
  }
function selectCanvasArea(signImageCanvas) {
	var oldContext = signImageCanvas.getContext('2d'),
	targetImage = document.getElementById('targetImage'),
	downloadContainer = document.getElementById('downloadContainer'),
	selectCanvas = document.getElementById('selectCanvas'),
	selectContext = selectCanvas.getContext('2d'),
	width = selectCanvas.width = signImageCanvas.width,
	height = selectCanvas.height = signImageCanvas.height;
	selectContext.fillStyle = '#000';
	downloadContainer.style.left = width + 25 + 'px';
	var clipCanvas = document.createElement('canvas'),
	clipContext = clipCanvas.getContext('2d');
	srcCanvas = clipCanvas;
	downloadContainer.appendChild(clipCanvas);
	selectCanvas.onmousedown = function (event) {
		console.log("x="+event.clientX+" "+"y="+event.clientY);
		let topOffset = jQuery('#selectCanvas').offset().top;
		let leftOffset = jQuery('#selectCanvas').offset().left;
		let clientX = event.clientX - leftOffset;
		let clientY = event.clientY - topOffset;
		console.log('Top Offset:', topOffset+" leftOffset:"+leftOffset);

		var x0 = Math.max(0, Math.min(clientX, width)),
		y0 = Math.max(0, Math.min(clientY, height));
		targetImage.style.display = 'none';
		function update(event) {
			var topOffset = jQuery('#selectCanvas').offset().top;
			var leftOffset = jQuery('#selectCanvas').offset().left;
			let clientX = event.clientX - leftOffset;
			let clientY = event.clientY - topOffset;
			var x = Math.max(0, Math.min(clientX, width)),
			y = Math.max(0, Math.min(clientY, height)),
			dx = x - x0, w = Math.abs(dx),
			dy = y - y0, h = Math.abs(dy);
			selectContext.clearRect(0, 0, width, height);
			selectContext.fillRect(x0, y0, dx, dy);
			clipCanvas.width = w;
			clipCanvas.height = h;
			if (w*h == 0) {
				downloadContainer.style.visibility = 'hidden';
			} else {
				downloadContainer.style.visibility = 'visible';
				clipContext.drawImage(signImageCanvas,
				x0 + Math.min(0, dx), y0 + Math.min(0, dy), w, h,
				0, 0, w, h);
				downloadContainer.style.visibility = (w*h == 0 ? 'hidden' : 'visible');
				downloadContainer.style.top = (Math.min(y0, y)) + 'px';
				downloadContainer.style.left = (clientX+50+w) + 'px';
			}
		};
		update(event);
		selectCanvas.onmousemove = update;
		document.onmouseup = function (event) {
			selectCanvas.onmousemove = undefined;
			document.onmouseup = undefined;
			targetImage.src = clipCanvas.toDataURL();
			targetImage.style.display = 'block';
		};
	};
};


