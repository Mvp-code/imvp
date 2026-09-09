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

var context, canvas;
var restorePoints = [];
var tool_list = ['Point', 'Eraser', 'Pencil', 'Line', 'Box', 'Circle', 'Text'];
var color_list = ['red', 'blue', 'green', 'brown', 'orange', 'yellow', 'pink', 'black', 'white', '#ECCF8D', '#660099', '#3D72A4', '#6D929B', '#E86850'];

// changes the stroke colour of the drawing canvas
function setColour(colour) {
    currentColour = colour;
    currentBrush.setColour(currentColour);
    strokeColour.css("background", currentColour);

}

function initializeDrawingPad (drawingCanvas, drawingContext) {
    // Find the canvas element.
    canvaso = drawingCanvas;
    if (!canvaso) {
      alert('Error: Cannot find the canvas element!');
      return;
    }

    if (!canvaso.getContext) {
      alert('Error: No canvas.getContext!');
      return;
    }

    // Get the 2D canvas context.
    contexto = drawingContext;
    if (!contexto) {
      alert('Error: Failed to getContext!');
      return;
    }

    // Add the temporary canvas.
    var container = canvaso.parentNode;
    canvas = document.createElement('canvas');
    if (!canvas) {
      alert('Error: I cannot create a new canvas element!');
      return;
    }

    canvas.id     = 'imageTemp';
    canvas.width  = canvaso.width;
    canvas.height = canvaso.height;
    container.appendChild(canvas);

    context = canvas.getContext('2d');
	context.globalCompositeOperation = "source-over";
}

// define a line brush for drawing straight lines
var LineBrush = Class.create({
    initialize: function (lineWidth, drawingCxt) {
        this.lineWidth = lineWidth;
		var tool = this;
		this.started = false;

        this.setColour = function (colour) {
            context.fillStyle = context.strokeStyle = colour;
            context.lineWidth = this.lineWidth;
            context.lineCap = "round";
            context.lineJoin = "round";
        };
        
		// Capture Mouse events starts
		canvas.addEventListener("mousedown", function(event){
			var position = getMouseXYPosition(event);
			tool.started = true;
			tool.x0 = position.X;
			tool.y0 = position.Y;
		})
		canvas.addEventListener("mouseup", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("mousemove", function (event) {
			var position = getMouseXYPosition(event);
			if (!tool.started) {
				return;
			}
			context.clearRect(0, 0, canvas.width, canvas.height);
			context.beginPath();
			context.moveTo(tool.x0, tool.y0);
			context.lineTo(position.X,   position.Y);
			context.stroke();
		})
		// Capture Mouse events ends
		
		// Capture Touch events starts
		canvas.addEventListener("touchstart", function (event) {
			var position = getMouseXYPosition(event);
			tool.started = true;
			tool.x0 = position.X;
			tool.y0 = position.Y;
		})
		canvas.addEventListener("touchend", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("touchmove", function (event) {
			var position = getMouseXYPosition(event);
			if (!tool.started) {
				return;
			}
			context.clearRect(0, 0, canvas.width, canvas.height);
			context.beginPath();
			context.moveTo(tool.x0, tool.y0);
			context.lineTo(position.X,   position.Y);
			context.stroke();
		})
		// prevent elastic scrolling
		canvas.addEventListener('touchmove',function(event){
			event.preventDefault();
		},false);
		// Capture Touch events ends
    }
});

// define a Box brush for drawing Boxes
var BoxBrush = Class.create({
    initialize: function (lineWidth, drawingCxt) {
        this.lineWidth = lineWidth;
		var tool = this;
		this.started = false;

        this.setColour = function (colour) {
            context.fillStyle = context.strokeStyle = colour;
            context.lineWidth = this.lineWidth;
            context.lineCap = "round";
            context.lineJoin = "round";
        };
        
		// Capture Mouse events starts
		canvas.addEventListener("mousedown", function(event){
			var position = getMouseXYPosition(event);
			tool.started = true;
			tool.x0 = position.X;
			tool.y0 = position.Y;
		})
		canvas.addEventListener("mouseup", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("mousemove", function (event) {
			var position = getMouseXYPosition(event);
			if (!tool.started) {
				return;
			}

			var x = Math.min(position.X,  tool.x0),
			y = Math.min(position.Y,  tool.y0),
			w = Math.abs(position.X - tool.x0),
			h = Math.abs(position.Y - tool.y0);

			context.clearRect(0, 0, canvas.width, canvas.height);

			if (!w || !h) {
				return;
			}
			context.strokeRect(x, y, w, h);
		})
		// Capture Mouse events ends
		
		// Capture Touch events starts
		canvas.addEventListener("touchstart", function (event) {
			var position = getMouseXYPosition(event);
			tool.started = true;
			tool.x0 = position.X;
			tool.y0 = position.Y;
		})
		canvas.addEventListener("touchend", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("touchmove", function (event) {
			var position = getMouseXYPosition(event);
			if (!tool.started) {
				return;
			}

			var x = Math.min(position.X,  tool.x0),
			y = Math.min(position.Y,  tool.y0),
			w = Math.abs(position.X - tool.x0),
			h = Math.abs(position.Y - tool.y0);

			context.clearRect(0, 0, canvas.width, canvas.height);

			if (!w || !h) {
				return;
			}
			context.strokeRect(x, y, w, h);
		})
		// prevent elastic scrolling
		canvas.addEventListener('touchmove',function(event){
			event.preventDefault();
		},false);
		// Capture Touch events ends
    }
});

// define a Circle brush for drawing Circles
var CircleBrush = Class.create({
    initialize: function (lineWidth, drawingCxt) {
        this.lineWidth = lineWidth;
		var tool = this;
		this.started = false;

        this.setColour = function (colour) {
            context.fillStyle = context.strokeStyle = colour;
            context.lineWidth = this.lineWidth;
            context.lineCap = "round";
            context.lineJoin = "round";
        };
        
		// Capture Mouse events starts
		canvas.addEventListener("mousedown", function(event){
			var position = getMouseXYPosition(event);
			tool.started = true;
			tool.x0 = position.X;
			tool.y0 = position.Y;
		})
		canvas.addEventListener("mouseup", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("mousemove", function (event) {
			var position = getMouseXYPosition(event);
			if (!tool.started) {
				return;
			}

			var x = Math.min(position.X,  tool.x0),
			y = Math.min(position.Y,  tool.y0),
			w = Math.abs(position.X - tool.x0),
			h = Math.abs(position.Y - tool.y0);

			context.clearRect(0, 0, canvas.width, canvas.height);

			 var angle = Math.atan(h/w);
			 var radius = h / Math.sin(angle);
   

		   context.beginPath();
		   context.arc(x, y, radius, 0, Math.PI*2, false); 
		   context.stroke();
		})
		// Capture Mouse events ends
		
		// Capture Touch events starts
		canvas.addEventListener("touchstart", function (event) {
			var position = getMouseXYPosition(event);
			tool.started = true;
			tool.x0 = position.X;
			tool.y0 = position.Y;
		})
		canvas.addEventListener("touchend", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("touchmove", function (event) {
			var position = getMouseXYPosition(event);
			if (!tool.started) {
				return;
			}

			var x = Math.min(position.X,  tool.x0),
			y = Math.min(position.Y,  tool.y0),
			w = Math.abs(position.X - tool.x0),
			h = Math.abs(position.Y - tool.y0);

			context.clearRect(0, 0, canvas.width, canvas.height);

			 var angle = Math.atan(h/w);
			 var radius = w / Math.sin(angle);
   

		   context.beginPath();
		   context.arc(x, y, radius, 0, Math.PI*2, false); 
		   context.stroke();
		})
		// prevent elastic scrolling
		canvas.addEventListener('touchmove',function(event){
			event.preventDefault();
		},false);
		// Capture Touch events ends
    }
});

// define a Point brush for marking Points
var PointBrush = Class.create({
    initialize: function (lineWidth, drawingCxt) {
        this.lineWidth = lineWidth;
		var tool = this;
		this.started = false;

        this.setColour = function (colour) {
            context.fillStyle = context.strokeStyle = colour;
            context.lineWidth = this.lineWidth;
            context.lineCap = "round";
            context.lineJoin = "round";
        };

		// Capture Mouse events starts
		canvas.addEventListener("mousedown", function(event){
			var position = getMouseXYPosition(event);
			var x = Math.min(position.X,  position.X),
			y = Math.min(position.Y,  position.Y);
			tool.started = true;
            context.beginPath();
            context.arc(x, y, lineWidth, 0, Math.PI*2, true); 
		    context.closePath();
			context.fill();

		})
		canvas.addEventListener("mouseup", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("mousemove", function (event) {
		})
		// Capture Mouse events ends
		
		// Capture Touch events starts
		canvas.addEventListener("touchstart", function (event) {
			var position = getMouseXYPosition(event);
			var x = Math.min(position.X,  position.X),
			y = Math.min(position.Y,  position.Y);
			tool.started = true;
            context.beginPath();
            context.arc(x, y, lineWidth, 0, Math.PI*2, true); 
		    context.closePath();
			context.fill();
		})
		canvas.addEventListener("touchend", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("touchmove", function (event) {
		})
		// prevent elastic scrolling
		canvas.addEventListener('touchmove',function(event){
			event.preventDefault();
		},false);
		// Capture Touch events ends
    }
 });

// define a pencil brush for drawing free-hand lines
var PencilBrush = Class.create({
    initialize: function (lineWidth, drawingCxt) {
        this.lineWidth = lineWidth;
		var tool = this;
		this.started = false;

        this.setColour = function (colour) {
            context.fillStyle = context.strokeStyle = colour;
            context.lineWidth = this.lineWidth;
            context.lineCap = "round";
            context.lineJoin = "round";
        };

		// Capture Mouse events starts
		canvas.addEventListener("mousedown", function(event){
			var position = getMouseXYPosition(event);
			tool.started = true;
            context.beginPath();
            context.moveTo(position.X--, position.Y--);
            context.lineTo(position.X, position.Y);
            context.stroke();
		})
		canvas.addEventListener("mouseup", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("mousemove", function (event) {
			 var position = getMouseXYPosition(event);
			 if (!tool.started) {
				return;
			}
             context.lineTo(position.X, position.Y);
             context.stroke();
		})
		// Capture Mouse events ends
		
		// Capture Touch events starts
		canvas.addEventListener("touchstart", function (event) {
			var position = getMouseXYPosition(event);
			tool.started = true;
            context.beginPath();
            context.moveTo(position.X--, position.Y--);
            context.lineTo(position.X, position.Y);
            context.stroke();
		})
		canvas.addEventListener("touchend", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("touchmove", function (event) {
			 var position = getMouseXYPosition(event);
			 if (!tool.started) {
				return;
			}
             context.lineTo(position.X, position.Y);
             context.stroke();
		})
		// prevent elastic scrolling
		canvas.addEventListener('touchmove',function(event){
			event.preventDefault();
		},false);
		// Capture Touch events ends
    }
});

// define a Eraser
var Eraser = Class.create({
    initialize: function (lineWidth, drawingCxt) {
        this.lineWidth = lineWidth;
		var tool = this;
		this.started = false;

        this.setColour = function (colour) {
            context.fillStyle = context.strokeStyle = 'white';
            context.lineWidth = this.lineWidth;
            context.lineCap = "round";
            context.lineJoin = "round";
        };

       // Capture Mouse events starts
		canvas.addEventListener("mousedown", function(event){
			var position = getMouseXYPosition(event);
			tool.started = true;
            context.beginPath();
            context.moveTo(position.X--, position.Y--);
            context.lineTo(position.X, position.Y);
            context.stroke();
		})
		canvas.addEventListener("mouseup", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("mousemove", function (event) {
			 var position = getMouseXYPosition(event);
			 if (!tool.started) {
				return;
			}
             context.lineTo(position.X, position.Y);
             context.stroke();
		})
		// Capture Mouse events ends
		
		// Capture Touch events starts
		canvas.addEventListener("touchstart", function (event) {
			var position = getMouseXYPosition(event);
			tool.started = true;
            context.beginPath();
            context.moveTo(position.X--, position.Y--);
            context.lineTo(position.X, position.Y);
            context.stroke();
		})
		canvas.addEventListener("touchend", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("touchmove", function (event) {
			 var position = getMouseXYPosition(event);
			 if (!tool.started) {
				return;
			}
             context.lineTo(position.X, position.Y);
             context.stroke();
		})
		// prevent elastic scrolling
		canvas.addEventListener('touchmove',function(event){
			event.preventDefault();
		},false);
		// Capture Touch events ends
    }
});

// define a Text brush for adding Text
var TextBrush = Class.create({
    initialize: function (lineWidth, drawingCxt) {
        this.lineWidth = lineWidth;
		var tool = this;
		this.started = false;

        this.setColour = function (colour) {
            context.fillStyle = colour;
            context.font = document.saveform.ItalicField.value + document.saveform.BoldField.value + document.saveform.fontWeight.value +'px ' + document.saveform.fontStyle.value;
        };

		// Capture Mouse events starts
		canvas.addEventListener("mousedown", function(event){
			var position = getMouseXYPosition(event);
			var x = Math.min(position.X,  position.X),
			y = Math.min(position.Y,  position.Y);
			tool.started = true;
			context.fillText(document.saveform.TextFieldVal.value, x, y);
		})
		canvas.addEventListener("mouseup", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("mousemove", function (event) {
		})
		// Capture Mouse events ends
		
		// Capture Touch events starts
		canvas.addEventListener("touchstart", function (event) {
			var position = getMouseXYPosition(event);
			var x = Math.min(position.X,  position.X),
			y = Math.min(position.Y,  position.Y);
			tool.started = true;
			context.fillText(document.saveform.TextFieldVal.value, x, y);
		})
		canvas.addEventListener("touchend", function (event) {
			if (tool.started) {
				tool.started = false;
				img_update(drawingContext);
			}
		})
		canvas.addEventListener("touchmove", function (event) {
		})
		// prevent elastic scrolling
		canvas.addEventListener('touchmove',function(event){
			event.preventDefault();
		},false);
		// Capture Touch events ends
    }
 });

function clearCanvas(drawingContext, drawingCanvas) {
  if(confirm("Do you want to clear your changes?")){	
	  drawingContext.clearRect(0, 0, drawingCanvas.width, drawingCanvas.height);
	  var w = drawingCanvas.width;
	  drawingCanvas.width = 1;
	  drawingCanvas.width = w;
	  restorePoints = [];
  } else {
	  return;
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

   // This function draws the #imageTemp canvas on top of #drawingCanvas, after which 
  // #imageTemp is cleared. This function is called each time when the user 
  // completes a drawing operation.
  function img_update (drawingContext) {
		saveRestorePoint();
		drawingContext.drawImage(canvas, 0, 0);
		context.clearRect(0, 0, canvas.width, canvas.height);
  }

function saveRestorePoint() {
	var oCanvas = document.getElementById("drawingCanvas");
	var canvasContext = document.getElementById("drawingCanvas").getContext("2d");		
	var imgSrc = canvasContext.getImageData(0, 0, oCanvas.width, oCanvas.height);
	restorePoints.push(imgSrc);
}

function undoDrawOnCanvas() {
	if (restorePoints.length > 0) {
		var canvasContext = document.getElementById("drawingCanvas").getContext("2d");		
		lastpixelData = restorePoints.pop();
		canvasContext.putImageData(lastpixelData, 0, 0);
	}
}

function selectAndDeselectTool(el) {
	for(i=0;i<tool_list.length;i++){
		var toolTDFromList = tool_list[i]+'TD';
		var toolFieldNameFromList = tool_list[i]+'Field';
		
		if(toolTDFromList == el.id){
			if(el.getAttribute('class') != 'button selected'){
				document.saveform[toolFieldNameFromList].value = 'YES';
				if(tool_list[i] == 'Text'){
					document.getElementById('fontWeightSelect').disabled=false;
					document.getElementById('fontStyleSelect').disabled=false;
					document.getElementById('lineSizeSelect').disabled=true;
					openDivPopup();
				} else {
					document.getElementById('fontWeightSelect').disabled=true;
					document.getElementById('fontStyleSelect').disabled=true;
					document.getElementById('lineSizeSelect').disabled=false;
				}
				el.setAttribute("class", "button selected");
			} else {
				document.saveform[toolFieldNameFromList].value = '';
				el.setAttribute("class", "button normal");
			}
		} else {
			if(document.saveform[toolFieldNameFromList] != null) // Remove after adding all tools
				document.saveform[toolFieldNameFromList].value = '';
			if(document.getElementById(toolTDFromList) != null) // Remove after adding all tools
				document.getElementById(toolTDFromList).setAttribute("class", "button normal");
		}
	}
}

function setSelectedPaletteColor(colorTDObj){
	var selectedColor = colorTDObj.id;
	for(i=0;i<color_list.length;i++){
		if(color_list[i] == selectedColor){
			if(colorTDObj.getAttribute('class') != 'pallete_selected'){
				document.saveform.colorPicker.value = selectedColor;
				colorTDObj.setAttribute("class", "pallete_selected");
			} else {
				document.saveform.colorPicker.value = '';
				colorTDObj.setAttribute("class", "pallete_normal");
			}
		} else {
			document.getElementById(color_list[i]).setAttribute("class", "pallete_normal");
		}
	}
	intializeCanvas();
}