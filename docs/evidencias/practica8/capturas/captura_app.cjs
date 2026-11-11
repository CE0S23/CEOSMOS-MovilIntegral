const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const output = __dirname;
  const requests = [];
  const responses = [];
  const errors = [];
  const browser = await chromium.launch({
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    headless: true,
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    page.on('request', request => requests.push({ method: request.method(), url: request.url() }));
    page.on('requestfailed', request => errors.push(`REQUEST ${request.url()}: ${request.failure()?.errorText}`));
    page.on('pageerror', error => errors.push(`PAGE ${error.message}`));
    page.on('console', message => {
      if (message.type() === 'error') errors.push(`CONSOLE ${message.text()}`);
    });
    page.on('response', response => {
      responses.push({ status: response.status(), url: response.url() });
      if (response.status() >= 400) errors.push(`HTTP ${response.status()} ${response.url()}`);
    });
    await page.goto('http://127.0.0.1:8765/', { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(1200);
    await page.screenshot({ path: path.join(output, 'app_inicio_sesion.png') });
    // El texto está dibujado por CanvasKit; la coordenada corresponde al botón visible en la captura.
    await page.mouse.click(930, 608);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(output, 'app_demo.png') });
    const result = {
      date: new Date().toISOString(),
      pageTitle: await page.title(),
      flutterView: await page.locator('flutter-view').count(),
      requestCount: requests.length,
      externalRequests: requests.filter(r => !r.url.startsWith('http://127.0.0.1:8765/')),
      externalResponses: responses.filter(r => !r.url.startsWith('http://127.0.0.1:8765/')),
      errors,
    };
    const blockedContext = await browser.newContext({ viewport: { width: 1280, height: 900 } });
    const blockedPage = await blockedContext.newPage();
    const blockedErrors = [];
    await blockedContext.route('https://fonts.gstatic.com/**', route => route.abort('blockedbyclient'));
    blockedPage.on('requestfailed', request => blockedErrors.push(`${request.url()}: ${request.failure()?.errorText}`));
    await blockedPage.goto('http://127.0.0.1:8765/', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await blockedPage.waitForTimeout(5000);
    await blockedPage.screenshot({ path: path.join(output, 'app_fuentes_bloqueadas.png') });
    result.simulatedFontBlock = { failures: blockedErrors, flutterView: await blockedPage.locator('flutter-view').count() };
    await blockedContext.close();
    fs.writeFileSync(path.join(output, 'navegador.json'), JSON.stringify(result, null, 2));
    console.log(JSON.stringify(result));
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
