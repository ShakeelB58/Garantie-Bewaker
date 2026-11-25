const {chromium}=require('playwright');const {spawn}=require('child_process');const fs=require('fs');
const [html,outDir]=process.argv.slice(2);const FPS=30;
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1080,height:1920}});
await p.goto('file://'+html);await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(300);
const scenes=await p.evaluate(()=>window.SCENES||[[0,3],[3,5.6],[5.6,8.9],[8.9,12],[12,14],[14,16]]);const list=[];
for(let i=0;i<scenes.length;i++){const [a,e]=scenes[i];const tag=require('path').basename(html,'.html');const tmp=`${outDir}/${tag}_s${i}.tmp.mp4`,fin=`${outDir}/${tag}_s${i}.mp4`;
 const ff=spawn('ffmpeg',['-y','-loglevel','error','-f','image2pipe','-framerate',String(FPS),'-c:v','mjpeg','-i','-','-c:v','libx264','-crf','18','-preset','veryfast','-pix_fmt','yuv420p','-r',String(FPS),tmp]);
 const n=Math.round((e-a)*FPS);
 for(let k=0;k<n;k++){const t=a+k/FPS;await p.evaluate(t=>render(t),t);const buf=await p.screenshot({type:'jpeg',quality:92});
   if(!ff.stdin.write(buf)) await new Promise(r=>ff.stdin.once('drain',r));}
 ff.stdin.end();const code=await new Promise(r=>ff.on('close',r));if(code!==0){console.error('ffmpeg fail',i);process.exit(1);}
 fs.renameSync(tmp,fin);list.push(`file '${fin}'`);console.log('scene',i,'ok',n);}
fs.writeFileSync(`${outDir}/${require('path').basename(html,'.html')}_list.txt`,list.join('\n')+'\n');await b.close();})();
