import { getDocument, GlobalWorkerOptions } from "./pdfjs/build/pdf.mjs";
import { EventBus, PDFViewer, PDFLinkService, PDFFindController } from "./pdfjs/web/pdf_viewer.mjs";

GlobalWorkerOptions.workerSrc = new URL("./pdfjs/build/pdf.worker.mjs", import.meta.url).href;
const container = document.querySelector("#viewerContainer");
const status = document.querySelector("#status");
const zoom = document.querySelector("#zoom");
const pageNumber = document.querySelector("#pageNumber");
const controls = document.querySelectorAll("header button, header input");
const eventBus = new EventBus();
const linkService = new PDFLinkService({ eventBus, externalLinkTarget: 2 });
const findController = new PDFFindController({ eventBus, linkService });
const viewer = new PDFViewer({ container, eventBus, linkService, findController });
linkService.setViewer(viewer);
let version;
let documentTask;
let documentData;

function captureView() {
  if (!viewer.pdfDocument) return null;
  const page = viewer.getPageView(viewer.currentPageNumber - 1).div;
  return {
    scale: viewer.currentScaleValue,
    page: viewer.currentPageNumber,
    x: container.scrollLeft,
    y: container.scrollTop - page.offsetTop,
  };
}

async function show(data, saved) {
  viewer.setDocument(null);
  linkService.setDocument(null);
  if (documentTask) await documentTask.destroy();
  const task = documentTask = getDocument({
    data: data.slice(0),
    cMapUrl: new URL("./pdfjs/cmaps/", import.meta.url).href,
    cMapPacked: true,
    standardFontDataUrl: new URL("./pdfjs/standard_fonts/", import.meta.url).href,
    wasmUrl: new URL("./pdfjs/wasm/", import.meta.url).href,
    isEvalSupported: false,
  });
  const pdf = await task.promise;
  const ready = new Promise(resolve => {
    const initialized = () => {
      eventBus.off("pagesinit", initialized);
      resolve();
    };
    eventBus.on("pagesinit", initialized);
  });
  viewer.setDocument(pdf);
  linkService.setDocument(pdf);
  await ready;
  viewer.currentScaleValue = saved?.scale || "page-width";
  await viewer.pagesPromise;
  if (saved) {
    const page = Math.min(saved.page, pdf.numPages);
    viewer.currentPageNumber = page;
    container.scrollLeft = saved.x;
    container.scrollTop = viewer.getPageView(page - 1).div.offsetTop + saved.y;
    viewer.update();
  }
  pageNumber.value = viewer.currentPageNumber;
  pageNumber.max = pdf.numPages;
  document.querySelector("#pageCount").textContent = `/ ${pdf.numPages}`;
}

async function load(next) {
  const response = await fetch(`document.pdf?v=${next}`, { cache: "no-store" });
  if (!response.ok) throw new Error("PDF unavailable");
  const data = await response.arrayBuffer();
  const saved = captureView();
  controls.forEach(control => { control.disabled = true; });
  try {
    await show(data, saved);
    documentData = data;
    version = next;
  } catch (error) {
    if (documentData) await show(documentData, saved);
    throw error;
  } finally {
    controls.forEach(control => { control.disabled = !viewer.pdfDocument; });
  }
}

eventBus.on("scalechanging", ({ scale }) => { zoom.value = Math.round(scale * 100); });
eventBus.on("pagechanging", ({ pageNumber: page }) => { pageNumber.value = page; });

function setZoom(value) {
  viewer.currentScaleValue = String(Math.min(500, Math.max(25, value || 100)) / 100);
  zoom.value = Math.round(viewer.currentScale * 100);
}

zoom.addEventListener("change", () => setZoom(zoom.valueAsNumber));
zoom.addEventListener("keydown", event => {
  if (event.key === "Enter") { setZoom(zoom.valueAsNumber); zoom.blur(); }
});
pageNumber.addEventListener("change", () => {
  viewer.currentPageNumber = Math.min(viewer.pagesCount, Math.max(1, pageNumber.valueAsNumber || 1));
  pageNumber.value = viewer.currentPageNumber;
});
pageNumber.addEventListener("keydown", event => {
  if (event.key === "Enter") { pageNumber.dispatchEvent(new Event("change")); pageNumber.blur(); }
});
document.querySelector("#zoomIn").addEventListener("click", () => setZoom(viewer.currentScale * 100 + 25));
document.querySelector("#zoomOut").addEventListener("click", () => setZoom(viewer.currentScale * 100 - 25));
document.querySelector("#fitWidth").addEventListener("click", () => { viewer.currentScaleValue = "page-width"; });
window.addEventListener("resize", () => {
  if (viewer.pdfDocument) viewer.currentScaleValue = viewer.currentScaleValue;
});
container.addEventListener("wheel", event => {
  if (!event.ctrlKey || !viewer.pdfDocument) return;
  event.preventDefault();
  setZoom(viewer.currentScale * 100 * Math.exp(-event.deltaY / 200));
}, { passive: false });

async function refresh() {
  try {
    const response = await fetch("version", { cache: "no-store" });
    if (!response.ok) throw new Error("Preview disconnected");
    const next = await response.json();
    if (next !== version) await load(next);
    status.hidden = true;
  } catch (error) {
    status.textContent = `Preview disconnected or PDF unavailable. Retrying… ${error.message}`;
    status.hidden = false;
  }
  setTimeout(refresh, 700);
}
refresh();
