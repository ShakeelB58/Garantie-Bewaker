const {chromium}=require('playwright');
const items=[['profiel',1080,1080],['p1',1080,1350],['p2',1080,1350],['p3',1080,1350],['p4',1080,1350],['p5',1080,1350],['p6',1080,1350],
 ['hl_hoe',1080,1920],['hl_tips',1080,1920],['hl_privacy',1080,1920],['hl_download',1080,1920],['hl_nieuw',1080,1920]];
(async()=>{const b=await chromium.launch();
for(const [k,w,h] of items){const p=await b.newPage({viewport:{width:w,height:h}});await p.goto('file://'+process.argv[2]+'#'+k);
 await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(400);await p.screenshot({path:`${process.argv[3]}/${k}.png`});await p.close();}
await b.close();})();
