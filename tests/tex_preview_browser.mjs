import assert from "node:assert/strict";
import { execFileSync, spawn } from "node:child_process";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { chromium } from "../scripts/pdf_preview/node_modules/playwright/index.mjs";

const directory = mkdtempSync(join(tmpdir(), "tex-preview-browser-"));
function compile(text, pages = 3) {
  writeFileSync(join(directory, "test.tex"), String.raw`\documentclass{article}
\begin{document}
${Array.from({ length: pages }, (_, index) => `${text} page ${index + 1}`).join(String.raw`\newpage` + "\n")}
\end{document}`);
  execFileSync("pdflatex", ["-interaction=nonstopmode", "-halt-on-error", "test.tex"], { cwd: directory, stdio: "pipe" });
}

compile("First");
const server = spawn("python3", ["scripts/tex_preview.py", join(directory, "test.pdf")]);
server.stderr.pipe(process.stderr);
const url = await new Promise((resolve, reject) => {
  const lines = createInterface({ input: server.stdout });
  lines.on("line", line => { if (line.startsWith("http://")) resolve(line); });
  server.on("exit", code => reject(new Error(`Preview exited: ${code}`)));
});
const browser = await chromium.launch({
  headless: true,
  executablePath: process.env.CHROME_PATH || (process.platform === "darwin" ? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" : undefined),
});

try {
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  page.setDefaultTimeout(10000);
  const errors = [];
  page.on("pageerror", error => errors.push(error.message));
  await page.goto(url);
  const zoom = page.getByRole("spinbutton", { name: "Zoom percent" });
  await zoom.waitFor({ state: "visible", timeout: 5000 });
  await page.waitForFunction(() => !document.querySelector("#zoom").disabled);
  await zoom.fill("175");
  await zoom.press("Enter");
  const number = page.getByRole("spinbutton", { name: "Page number" });
  await number.fill("2");
  await number.press("Enter");
  await page.waitForFunction(() => document.querySelector('.page[data-page-number="2"] canvas'));
  await page.locator("#viewerContainer").evaluate(element => { element.scrollTop += 140; });
  const before = await page.locator("#viewerContainer").evaluate(element => ({ x: element.scrollLeft, y: element.scrollTop }));
  compile("Second");
  server.stdin.write("refresh\n");
  await page.waitForFunction(() => document.querySelector("#viewer").textContent.includes("Second page 2"));
  assert.equal(await zoom.inputValue(), "175");
  assert.equal(await number.inputValue(), "2");
  const after = await page.locator("#viewerContainer").evaluate(element => ({ x: element.scrollLeft, y: element.scrollTop }));
  assert.ok(Math.abs(before.y - after.y) < 4, `Vertical scroll changed: ${before.y} -> ${after.y}`);
  assert.ok(Math.abs(before.x - after.x) < 4, `Horizontal scroll changed: ${before.x} -> ${after.x}`);
  await page.screenshot({ path: join(tmpdir(), "tex-preview-desktop.png") });

  compile("Shorter", 1);
  server.stdin.write("refresh\n");
  await page.waitForFunction(() => document.querySelector("#viewer").textContent.includes("Shorter page 1"));
  assert.equal(await zoom.inputValue(), "175");
  assert.equal(await number.inputValue(), "1");
  writeFileSync(join(directory, "test.pdf"), "%PDF-1.4\ninvalid\n%%EOF");
  server.stdin.write("refresh\n");
  await page.getByRole("status").filter({ hasText: "PDF unavailable" }).waitFor();
  await page.waitForFunction(() => document.querySelector("#viewer").textContent.includes("Shorter page 1"));
  assert.equal(await zoom.inputValue(), "175");
  compile("Recovered", 1);
  server.stdin.write("refresh\n");
  await page.waitForFunction(() => document.querySelector("#viewer").textContent.includes("Recovered page 1"));
  assert.equal(await zoom.inputValue(), "175");
  await page.route("**/version", route => route.abort());
  await page.getByRole("status").filter({ hasText: "disconnected" }).waitFor();
  assert.equal(await zoom.inputValue(), "175");
  await page.unroute("**/version");
  await page.waitForFunction(() => document.querySelector("#status").hidden);

  await page.setViewportSize({ width: 390, height: 844 });
  await page.getByRole("button", { name: "Fit width" }).click();
  await page.screenshot({ path: join(tmpdir(), "tex-preview-mobile.png") });
  assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
  assert.deepEqual(errors, []);
  console.log("PASS: zoom and scroll survive PDF updates; shorter documents, reconnect and mobile layout work");
} catch (error) {
  for (const context of browser.contexts()) {
    for (const page of context.pages()) {
      console.error(await page.locator("#status").textContent());
      console.error(await page.locator("#viewer").textContent());
      console.error(await page.locator("#pageNumber").inputValue());
      await page.screenshot({ path: join(tmpdir(), "tex-preview-failure.png") });
    }
  }
  throw error;
} finally {
  await browser.close();
  server.stdin.end();
  await new Promise(resolve => { if (server.exitCode !== null) resolve(); else server.once("exit", resolve); });
  rmSync(directory, { recursive: true, force: true });
}
