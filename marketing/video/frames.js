const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1080,height:1920}});
await p.goto('file://'+process.argv[2]);await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(300);
for(const t of process.argv.slice(4).map(Number)){await p.evaluate(t=>render(t),t);await p.screenshot({path:`${process.argv[3]}/f_${t}.jpg`,type:'jpeg',quality:80});}
await b.close();})();
