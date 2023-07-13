const getPixelRatio = context => {
  var backingStore =
    context.backingStorePixelRatio ||
    context.webkitBackingStorePixelRatio ||
    context.mozBackingStorePixelRatio ||
    context.msBackingStorePixelRatio ||
    context.oBackingStorePixelRatio ||
    context.backingStorePixelRatio ||
    1;
  
  return (window.devicePixelRatio || 1) / backingStore;
};

const resize = (canvas, ratio) => {
  canvas.width = window.innerWidth * ratio;
  canvas.height = window.innerHeight * ratio;
  canvas.style.width = `${window.innerWidth}px`;
  canvas.style.height = `${window.innerHeight}px`;
};

function canvasToPagePosition(canvas, x, y) {
  // Get the bounding rectangle of the canvas
  const rect = canvas.getBoundingClientRect();

  // Account for any scrolling offsets
  const scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
  const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

  // Calculate the page position
  const pageX = rect.left + x + scrollLeft;
  const pageY = rect.top + y + scrollTop;

  return { x: pageX, y: pageY };
}

function pageToCanvasPosition(canvas, pageX, pageY) {
  // Get the bounding rectangle of the canvas
  const rect = canvas.getBoundingClientRect();

  // Account for any scrolling offsets
  const scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
  const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

  // Calculate the canvas position
  const x = pageX - rect.left - scrollLeft;
  const y = pageY - rect.top - scrollTop;

  return { x, y };
}

function getHandle(id) {
  const specificHandle = document.getElementById('live-flow-handle-' + id);
  if(specificHandle) {
    return specificHandle;
  }

  const container = document.getElementById("live-flow-node-" + id + "-container");
  if (container) {
    return container.querySelector(".live-flow-handle-primary")
  }
}

function centerOf(div) {
  const {top: top, left: left, bottom: bottom, right: right} = div.getBoundingClientRect();
  return {x: left + (right - left) / 2, y: top + (bottom - top) / 2};
}

function drawEdge(edge, from, to) {
  const fromHandle = getHandle(from);
  const toHandle = getHandle(to);
  const {x: x1, y: y1} = centerOf(fromHandle);
  const {x: x2, y: y2} = centerOf(toHandle);
  drawLine(edge, x1, y1, x2, y2);
}

function drawLine(svg, x1, y1, x2, y2) {
  const newLine = document.createElementNS('http://www.w3.org/2000/svg','line');
  newLine.setAttribute('x1', x1);
  newLine.setAttribute('y1', y1);
  newLine.setAttribute('x2', x2);
  newLine.setAttribute('y2', y2);
  newLine.setAttribute("stroke", "black")
  console.log(svg.innerHTML);
  svg.innerHTML = "";
  svg.appendChild(newLine);
}

function render(hook, draggingId) {
  const canvas = hook.el.firstElementChild;
  const el = hook.el;
  const nodeIds = el.dataset.ids.split(",");

  nodeIds.forEach((id) => {
    if(id !== draggingId) {
      const nodeContainer = document.getElementById("live-flow-node-" + id + "-container");
      const div = document.getElementById("live-flow-node-" + id);

      const {x, y} = canvasToPagePosition(canvas, parseInt(div.dataset.positionX), parseInt(div.dataset.positionY))
      nodeContainer.style.left = x.toString() + 'px';
      nodeContainer.style.top = y.toString() + 'px';

      if (nodeContainer.style.display === "none") {
        nodeContainer.style.display = ''
      }
    }
  });

  const edges = document.querySelectorAll(".live-flow-edge-" + el.id)
  edges.forEach((edge) => {
    const from = edge.dataset.from;
    const to = edge.dataset.to;
    drawEdge(edge, from, to);
  })
}

function addEventHandlers(hook, canvas) {
  hook.el.parentElement.parentElement.addEventListener("mousemove", function(e) {
    if (hook.dragging) {
      if(hook.dragging.type === "node") {
        hook.dragging.el.style.left = (e.clientX + hook.dragging.from.x) + 'px'
        hook.dragging.el.style.top = (e.clientY + hook.dragging.from.y) + 'px'
        render(hook, hook.dragging.id)
      }

      if(hook.dragging.type === "handle") {
        const {x: x1, y: y1} = centerOf(hook.dragging.el);

        drawLine(hook.dragging.svg, x1, y1, e.clientX, e.clientY);
        console.log(hook.dragging.svg)
      }
    }
    return true
  })

  hook.el.parentElement.parentElement.addEventListener("mousedown" , function(e) { 
    if(hook.dragging) {
      return true;
    };
    const overlappingElements = document.elementsFromPoint(e.pageX, e.pageY);
    const clicked = overlappingElements.find((e) => e.dataset.flowIs)
    if(clicked.dataset.flowIs === "node") {
      hook.dragging = {el: clicked.parentElement, type: "node", id: clicked.dataset.nodeId, from: {x: clicked.parentElement.offsetLeft - e.clientX, y: clicked.parentElement.offsetTop - e.clientY}};
      return true;
    }
    if(clicked.dataset.flowIs === "handle") {
      const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
      hook.dragging = {el: clicked, svg: svg, type: "handle", id: clicked.dataset.nodeId, from: {x: clicked.parentElement.offsetLeft - e.clientX, y: clicked.parentElement.offsetTop - e.clientY}}
      svg.id = hook.el.id + 'dragging-edge';
      svg.style.position = "absolute";
      svg.width = "100%"
      svg.height = "100%"
      hook.el.parentElement.prepend(svg);
      return true;
    }
  });

  hook.el.parentElement.parentElement.addEventListener("mouseup", function(e) {
    if(hook.dragging && hook.dragging.type === "node") {
      const left = hook.dragging.el.style.left;
      const top = hook.dragging.el.style.top;
      const position = pageToCanvasPosition(canvas, parseInt(left), parseInt(top))
      hook.pushEventTo(hook.el, "new-position", {id: hook.dragging.id, position: position})
    }
    delete hook.dragging;

    return true
  });

  hook.el.parentElement.parentElement.addEventListener("mouseleave", function() {
    delete hook.dragging;
    return true
  })
}

export const LiveFlow = {
  mounted() {
    this.divsSetup = {};
    this.handlesSetup = {};
    let canvas = this.el.firstElementChild.firstElementChild;
    let context = canvas.getContext("2d");
    let ratio = getPixelRatio(context);
    addEventHandlers(this, canvas)
    
    resize(canvas, ratio);
    render(this);
    Object.assign(this, { canvas, context });
  },
  updated(e) {
    render(this)
  }
};

export const LiveFlowNode = {
  beforeUpdate() {
    this.prevTop = this.el.style.top;
    this.prevLeft = this.el.style.left;
  },

  updated() {
    this.el.style.top = this.prevTop;
    this.el.style.left = this.prevLeft;
  },
}