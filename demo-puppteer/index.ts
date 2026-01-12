import { connect } from "puppeteer-core";

async function main() {
    try {
        const browser = await connect({
            browserURL: 'http://192.168.0.30:9223',
            slowMo: 100
        })
        console.log('Connected to browser');


        const page = await browser.newPage();
        await page.goto('https://www.google.com');
        await page.screenshot({path: 'demo.png'});
        await page.close();
        await browser.close();
    } catch (e) {
        console.log(e);
    }
}

main();