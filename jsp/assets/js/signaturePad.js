const sign_pad_canvas = document.querySelector(".signature-pad-canvas");
const sign_pad_form = document.querySelector(".signature-pad-form");
const sign_pad_clear = document.querySelector(".signature-pad-clear");

const sign_pad_ctx = sign_pad_canvas.getContext('2d');

sign_pad_canvas.width = 300 ;
sign_pad_canvas.height = 100 ;

const handlePointerDown = (event) => {
  writingMode = true;
  sign_pad_ctx.beginPath();
  const [positionX, positionY] = getCursorPosition(event);
  sign_pad_ctx.moveTo(positionX, positionY);
}

const handlePointerUp = () => {
  writingMode = false;
}

const handlePointerMove = (event) => {
  if (!writingMode) return
  const [positionX, positionY] = getCursorPosition(event);
  sign_pad_ctx.lineTo(positionX, positionY);
  sign_pad_ctx.stroke();
}

let writingMode = false;

sign_pad_canvas.addEventListener('pointerdown', handlePointerDown, {passive: true});
sign_pad_canvas.addEventListener('pointerup', handlePointerUp, {passive: true});
sign_pad_canvas.addEventListener('pointermove', handlePointerMove, {passive: true});


const getCursorPosition = (event) => {
  positionX = event.clientX - event.target.getBoundingClientRect().x;
  positionY = event.clientY - event.target.getBoundingClientRect().y;
  return [positionX, positionY];
}

sign_pad_ctx.lineWidth = 3;
sign_pad_ctx.lineJoin = sign_pad_ctx.lineCap = 'round';

const clearPad = () => {
  sign_pad_ctx.clearRect(0, 0, sign_pad_canvas.width, sign_pad_canvas.height);
}

sign_pad_clear.addEventListener('click', (event) => {
  event.preventDefault();
  clearPad();
})
