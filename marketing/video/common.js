const $=id=>document.getElementById(id);
const clamp=(x,a=0,b=1)=>Math.min(b,Math.max(a,x));
const lin=(t,a,b)=>clamp((t-a)/(b-a));
const ease=x=>x<.5?4*x*x*x:1-Math.pow(-2*x+2,3)/2;
const out=x=>1-Math.pow(1-x,3);
const back=x=>{x=clamp(x);const c1=1.70158,c3=c1+1;return 1+c3*Math.pow(x-1,3)+c1*Math.pow(x-1,2)};
const win=(t,a,b,fi=.35,fo=.35)=>Math.min(lin(t,a,a+fi),1-lin(t,b-fo,b));
function addEnd(tag){const e=document.createElement('div');e.id='end';e.className='abs';
 e.innerHTML=`<img src="a/icoon-512.png"><div class="name">Bon<span>vrij</span></div><div class="tag">${tag}</div>
 <div class="pills"><div class="pill">Gratis</div><div class="pill">Geen account</div><div class="pill">Geen reclame</div></div><div class="url">bonvrij.nl</div>`;
 $('stage').appendChild(e);}
function renderEnd(t,a){const e=lin(t,a,a+.5);$('end').style.opacity=e;
 $('end').querySelector('img').style.transform=`scale(${0.5+0.5*back(e)})`;
 document.querySelectorAll('#end .pill').forEach((p,i)=>{const q=lin(t,a+.4+i*.15,a+.8+i*.15);p.style.opacity=q;p.style.transform=`translateY(${(1-out(q))*30}px)`;});
 const u=lin(t,a+1,a+1.4);const url=$('end').querySelector('.url');url.style.opacity=u;url.style.transform=`scale(${0.8+0.2*back(u)})`;}
function heads(t,list){let ht='',st='',ho=0,hy=0;
 for(const [a,b,h,s] of list){if(t>=a&&t<b){ht=h;st=s;ho=win(t,a,b,.3,.3);hy=(1-out(lin(t,a,a+.45)))*40;}}
 $('h1').textContent=ht;$('s1').textContent=st;$('h1').style.opacity=ho;$('s1').style.opacity=ho*(st?1:0);
 $('h1').style.transform=`translateY(${hy}px)`;$('s1').style.transform=`translateY(${hy*1.4}px)`;}
